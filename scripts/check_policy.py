"""The repo's workflow and docs policy, as one check.

Workflows (`.github/workflows/*.yml`) and composite actions (`actions/*/action.yml`):

- every `uses:` is a full commit SHA with a `# vX.Y.Z` comment, a local `./` path,
  or a `docker://` image pinned by digest;
- no `${{ }}` inside `run:`, because an expression there is pasted into the shell
  before it runs; pass it through `env:` instead;
- every job sets `timeout-minutes`, except a job that calls a reusable workflow,
  where GitHub doesn't allow the key;
- every `actions/checkout` sets `persist-credentials: false`, unless the job is in
  CHECKOUT_KEEPS_CREDENTIALS with its reason;
- no workflow runs on `pull_request_target` (decision record 0010).

Docs (every `*.md`): relative links and their anchors resolve, and no file contains
an em dash (decision record 0017).

Run `python scripts/check_policy.py` from the repo root. It prints one line per
problem and exits 1 when there is any. The test suite runs it over the repo too.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml

# (path relative to the repo root, job id) -> why that checkout keeps its token.
# Empty: nothing here needs git credentials after checkout yet.
CHECKOUT_KEEPS_CREDENTIALS: dict[tuple[str, str], str] = {}

# Directories never scanned for docs: tool state, not the repo's own pages. The
# tests build their rule-breaking fixtures in temporary directories, not here.
SKIP_DIRS = {".git", ".venv", "node_modules", ".terraform"}

EM_DASH = "—"

_SHA_REF = re.compile(r"^[^@\s]+@[0-9a-f]{40}$")
_VERSION_COMMENT = re.compile(r"#\s*v\d+\.\d+\.\d+\b")
_DOCKER_DIGEST = re.compile(r"^docker://[^@\s]+@sha256:[0-9a-f]{64}$")
_FENCE = re.compile(r"^\s*(```|~~~)")
_CODE_SPAN = re.compile(r"(`+)(?:(?!\1).)+?\1")
_LINK = re.compile(r"\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
_HEADING = re.compile(r"^\s{0,3}(#{1,6})\s+(.*?)\s*#*\s*$")
_SCHEME = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*:")


def check_repo(root: Path) -> list[str]:
    """Every problem in the repo at `root`, as `path:line: message` strings."""
    problems: list[str] = []
    for path in sorted(_files(root, ".github/workflows", ("*.yml", "*.yaml"))):
        problems += check_yaml_file(path, root, is_workflow=True)
    for path in sorted(_files(root, "actions", ("*/action.yml", "*/action.yaml"))):
        problems += check_yaml_file(path, root, is_workflow=False)
    for path in sorted(_markdown_files(root)):
        problems += check_markdown_file(path, root)
    return problems


def check_yaml_file(path: Path, root: Path, *, is_workflow: bool) -> list[str]:
    rel = path.relative_to(root).as_posix()
    text = path.read_text(encoding="utf-8")
    try:
        node = yaml.compose(text)
        doc = yaml.safe_load(text)
    except yaml.YAMLError as err:
        return [f"{rel}: not valid YAML: {err}"]
    if node is None or not isinstance(doc, dict):
        return [f"{rel}: empty or not a mapping"]

    lines = text.splitlines()
    problems = [f"{rel}:{line}: {msg}" for line, msg in _check_uses(node, lines)]
    if is_workflow:
        problems += [f"{rel}: {msg}" for msg in _check_workflow(doc, rel)]
    else:
        steps = (doc.get("runs") or {}).get("steps") or []
        problems += [f"{rel}: {msg}" for msg in _check_steps(steps, rel, job_id=None)]
    return problems


def _check_uses(node: yaml.Node, lines: list[str]):
    """Yield (line number, message) for every `uses:` that isn't pinned."""
    for key, value in _mapping_pairs(node):
        if key.value != "uses" or not isinstance(value, yaml.ScalarNode):
            continue
        ref = value.value.strip()
        line_no = value.start_mark.line + 1
        if ref.startswith("./"):
            continue
        if ref.startswith("docker://"):
            if not _DOCKER_DIGEST.match(ref):
                yield line_no, f"`uses: {ref}` must pin the image by @sha256 digest"
            continue
        if not _SHA_REF.match(ref):
            yield line_no, f"`uses: {ref}` must pin a full 40-character commit SHA"
            continue
        comment = lines[value.start_mark.line][value.end_mark.column :]
        if not _VERSION_COMMENT.search(comment):
            yield line_no, f"`uses: {ref}` needs its version in a comment, as `# vX.Y.Z`"


def _mapping_pairs(node: yaml.Node):
    """Every (key node, value node) pair in the tree, depth first."""
    if isinstance(node, yaml.MappingNode):
        for key, value in node.value:
            if isinstance(key, yaml.ScalarNode):
                yield key, value
            yield from _mapping_pairs(value)
    elif isinstance(node, yaml.SequenceNode):
        for item in node.value:
            yield from _mapping_pairs(item)


def _check_workflow(doc: dict, rel: str) -> list[str]:
    problems: list[str] = []
    # YAML 1.1 reads a bare `on` key as the boolean True.
    triggers = doc.get("on", doc.get(True))
    if "pull_request_target" in _trigger_names(triggers):
        problems.append("`pull_request_target` runs a fork's code with this repo's secrets; use `pull_request`")
    for job_id, job in (doc.get("jobs") or {}).items():
        if not isinstance(job, dict):
            continue
        if "uses" in job:
            continue
        if "timeout-minutes" not in job:
            problems.append(f"job `{job_id}` needs `timeout-minutes`")
        problems += _check_steps(job.get("steps") or [], rel, job_id=job_id)
    return problems


def _trigger_names(triggers) -> set[str]:
    if isinstance(triggers, str):
        return {triggers}
    if isinstance(triggers, list):
        return {t for t in triggers if isinstance(t, str)}
    if isinstance(triggers, dict):
        return {t for t in triggers if isinstance(t, str)}
    return set()


def _check_steps(steps: list, rel: str, *, job_id: str | None) -> list[str]:
    problems: list[str] = []
    where = f"job `{job_id}`" if job_id else "the action"
    for index, step in enumerate(steps, start=1):
        if not isinstance(step, dict):
            continue
        name = step.get("name") or step.get("id") or f"step {index}"
        run = step.get("run")
        if isinstance(run, str) and "${{" in run:
            problems.append(f"{where}, `{name}`: `${{{{ }}}}` inside `run:`; pass the value through `env:`")
        uses = step.get("uses")
        if isinstance(uses, str) and uses.split("@")[0] == "actions/checkout":
            keep = (step.get("with") or {}).get("persist-credentials")
            if keep not in (False, "false") and (rel, job_id or "") not in CHECKOUT_KEEPS_CREDENTIALS:
                problems.append(f"{where}, `{name}`: checkout must set `persist-credentials: false`")
    return problems


def check_markdown_file(path: Path, root: Path) -> list[str]:
    rel = path.relative_to(root).as_posix()
    text = path.read_text(encoding="utf-8")
    problems: list[str] = []
    for line_no, line in enumerate(text.splitlines(), start=1):
        if EM_DASH in line:
            problems.append(f"{rel}:{line_no}: em dash; use a period, comma, colon or parentheses")
    for line_no, target in _links(text):
        message = _check_link(path, target)
        if message:
            problems.append(f"{rel}:{line_no}: {message}")
    return problems


def _links(text: str):
    """Yield (line number, target) for each markdown link outside code."""
    in_fence = False
    for line_no, line in enumerate(text.splitlines(), start=1):
        if _FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for match in _LINK.finditer(_CODE_SPAN.sub("", line)):
            yield line_no, match.group(1)


def _check_link(path: Path, target: str) -> str | None:
    if _SCHEME.match(target):
        return None
    file_part, _, anchor = target.partition("#")
    dest = (path.parent / file_part).resolve() if file_part else path
    if not dest.exists():
        return f"link `{target}` points at a file that doesn't exist"
    if anchor and dest.is_file() and dest.suffix == ".md":
        if anchor.lower() not in heading_anchors(dest.read_text(encoding="utf-8")):
            return f"link `{target}` points at a heading that doesn't exist"
    return None


def heading_anchors(text: str) -> set[str]:
    """The anchors GitHub generates for a markdown file's headings."""
    anchors: set[str] = set()
    seen: dict[str, int] = {}
    in_fence = False
    for line in text.splitlines():
        if _FENCE.match(line):
            in_fence = not in_fence
            continue
        match = None if in_fence else _HEADING.match(line)
        if not match:
            continue
        slug = re.sub(r"[^\w\- ]", "", match.group(2).lower()).replace(" ", "-")
        count = seen.get(slug, 0)
        seen[slug] = count + 1
        anchors.add(slug if count == 0 else f"{slug}-{count}")
    return anchors


def _files(root: Path, folder: str, patterns: tuple[str, ...]):
    base = root / folder
    if not base.is_dir():
        return
    for pattern in patterns:
        yield from base.glob(pattern)


def _markdown_files(root: Path):
    for path in root.rglob("*.md"):
        if not SKIP_DIRS.intersection(path.relative_to(root).parts):
            yield path


def main(argv: list[str]) -> int:
    root = Path(argv[1] if len(argv) > 1 else ".").resolve()
    problems = check_repo(root)
    for problem in problems:
        print(problem)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
