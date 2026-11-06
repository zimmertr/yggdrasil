"""The policy check: each rule fires on a fixture that breaks it, stays quiet on one
that follows it, and the repo itself passes."""

import io
import tempfile
import textwrap
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

from scripts import check_policy

SHA = "0123456789abcdef0123456789abcdef01234567"
DIGEST = "sha256:" + "ab" * 32
REPO_ROOT = Path(__file__).resolve().parent.parent


def workflow(steps: str = "", *, on: str = "pull_request", job_extra: str = "    timeout-minutes: 5\n") -> str:
    """A one-job workflow, with `steps` indented under the job."""
    body = textwrap.indent(textwrap.dedent(steps), "      ")
    return f"on: {on}\njobs:\n  build:\n    runs-on: ubuntu-latest\n{job_extra}    steps:\n{body}"


GOOD_STEPS = f"""\
- uses: actions/checkout@{SHA} # v7.0.1
  with:
    persist-credentials: false
- run: echo "$TITLE"
  env:
    TITLE: ${{{{ github.event.pull_request.title }}}}
"""


class RepoCase(unittest.TestCase):
    """A temporary repo the tests write files into."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def write(self, rel: str, text: str) -> Path:
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def problems(self) -> list[str]:
        return check_policy.check_repo(self.root)

    def assertOneProblem(self, needle: str):
        problems = self.problems()
        self.assertEqual(len(problems), 1, problems)
        self.assertIn(needle, problems[0])


class TestUses(RepoCase):
    def test_a_pinned_workflow_passes(self):
        self.write(".github/workflows/ok.yml", workflow(GOOD_STEPS))
        self.assertEqual(self.problems(), [])

    def test_a_tag_fails(self):
        self.write(".github/workflows/w.yml", workflow("- uses: actions/setup-python@v6\n"))
        self.assertOneProblem("full 40-character commit SHA")

    def test_a_short_sha_fails(self):
        self.write(".github/workflows/w.yml", workflow(f"- uses: actions/setup-python@{SHA[:12]} # v6.0.0\n"))
        self.assertOneProblem("full 40-character commit SHA")

    def test_a_sha_without_its_version_comment_fails(self):
        self.write(".github/workflows/w.yml", workflow(f"- uses: actions/setup-python@{SHA}\n"))
        self.assertOneProblem("# vX.Y.Z")

    def test_a_major_only_comment_fails(self):
        self.write(".github/workflows/w.yml", workflow(f"- uses: actions/setup-python@{SHA} # v6\n"))
        self.assertOneProblem("# vX.Y.Z")

    def test_the_problem_names_the_line(self):
        self.write(".github/workflows/w.yml", workflow("- uses: actions/setup-python@v6\n"))
        self.assertTrue(self.problems()[0].startswith(".github/workflows/w.yml:7:"), self.problems())

    def test_a_local_path_passes(self):
        self.write(".github/workflows/w.yml", workflow("- uses: ./actions/check-pr-title\n"))
        self.assertEqual(self.problems(), [])

    def test_a_docker_image_by_digest_passes(self):
        self.write(".github/workflows/w.yml", workflow(f"- uses: docker://alpine:3@{DIGEST}\n"))
        self.assertEqual(self.problems(), [])

    def test_a_docker_image_by_tag_fails(self):
        self.write(".github/workflows/w.yml", workflow("- uses: docker://alpine:3\n"))
        self.assertOneProblem("@sha256 digest")

    def test_a_reusable_workflow_call_is_checked_too(self):
        self.write(
            ".github/workflows/w.yml",
            "on: push\njobs:\n  release:\n    uses: zimmertr/yggdrasil/.github/workflows/release.yml@main\n",
        )
        self.assertOneProblem("full 40-character commit SHA")

    def test_uses_inside_a_composite_action_is_checked(self):
        self.write("actions/a/action.yml", "runs:\n  using: composite\n  steps:\n    - uses: actions/cache@v4\n")
        self.assertOneProblem("full 40-character commit SHA")

    def test_text_that_mentions_uses_inside_run_is_ignored(self):
        self.write(".github/workflows/w.yml", workflow("- run: |\n    echo 'uses: actions/cache@v4'\n"))
        self.assertEqual(self.problems(), [])


class TestRunExpressions(RepoCase):
    def test_an_expression_inside_run_fails(self):
        self.write(".github/workflows/w.yml", workflow('- run: echo "${{ github.head_ref }}"\n'))
        self.assertOneProblem("pass the value through `env:`")

    def test_an_expression_in_env_passes(self):
        self.write(".github/workflows/w.yml", workflow(GOOD_STEPS))
        self.assertEqual(self.problems(), [])

    def test_an_expression_inside_a_composite_run_fails(self):
        self.write(
            "actions/a/action.yml",
            "runs:\n  using: composite\n  steps:\n    - name: Echo\n      shell: bash\n"
            "      run: echo ${{ inputs.x }}\n",
        )
        self.assertOneProblem("the action, `Echo`")


class TestTimeouts(RepoCase):
    def test_a_job_without_a_timeout_fails(self):
        self.write(".github/workflows/w.yml", workflow("- run: true\n", job_extra=""))
        self.assertOneProblem("job `build` needs `timeout-minutes`")

    def test_a_reusable_workflow_caller_needs_no_timeout(self):
        self.write(
            ".github/workflows/w.yml",
            f"on: push\njobs:\n  test:\n    uses: ./.github/workflows/test.yml\n  other:\n"
            f"    uses: zimmertr/yggdrasil/.github/workflows/x.yml@{SHA} # v0.1.0\n",
        )
        self.assertEqual(self.problems(), [])


class TestCheckout(RepoCase):
    def test_a_checkout_that_keeps_credentials_fails(self):
        self.write(".github/workflows/w.yml", workflow(f"- uses: actions/checkout@{SHA} # v7.0.1\n"))
        self.assertOneProblem("persist-credentials: false")

    def test_persist_credentials_true_fails(self):
        self.write(
            ".github/workflows/w.yml",
            workflow(f"- uses: actions/checkout@{SHA} # v7.0.1\n  with:\n    persist-credentials: true\n"),
        )
        self.assertOneProblem("persist-credentials: false")

    def test_the_string_false_passes(self):
        self.write(
            ".github/workflows/w.yml",
            workflow(f"- uses: actions/checkout@{SHA} # v7.0.1\n  with:\n    persist-credentials: 'false'\n"),
        )
        self.assertEqual(self.problems(), [])

    def test_an_allowlisted_job_may_keep_credentials(self):
        self.write(".github/workflows/w.yml", workflow(f"- uses: actions/checkout@{SHA} # v7.0.1\n"))
        allow = {(".github/workflows/w.yml", "build"): "pushes a tag"}
        with mock.patch.dict(check_policy.CHECKOUT_KEEPS_CREDENTIALS, allow):
            self.assertEqual(self.problems(), [])

    def test_a_checkout_in_a_composite_action_is_checked(self):
        self.write(
            "actions/a/action.yml",
            f"runs:\n  using: composite\n  steps:\n    - uses: actions/checkout@{SHA} # v7.0.1\n",
        )
        self.assertOneProblem("the action, `step 1`")


class TestPullRequestTarget(RepoCase):
    def test_it_fails_as_a_string(self):
        self.write(".github/workflows/w.yml", workflow("- run: true\n", on="pull_request_target"))
        self.assertOneProblem("pull_request_target")

    def test_it_fails_in_a_list(self):
        self.write(".github/workflows/w.yml", workflow("- run: true\n", on="[push, pull_request_target]"))
        self.assertOneProblem("pull_request_target")

    def test_it_fails_as_a_mapping_key(self):
        self.write(".github/workflows/w.yml", workflow("- run: true\n", on="\n  pull_request_target:\n    types: [opened]"))
        self.assertOneProblem("pull_request_target")

    def test_pull_request_passes(self):
        self.write(".github/workflows/w.yml", workflow("- run: true\n", on="\n  pull_request:\n  push:"))
        self.assertEqual(self.problems(), [])

    def test_a_quoted_on_key_is_read_too(self):
        self.write(".github/workflows/w.yml", workflow("- run: true\n").replace("on:", '"on":', 1).replace(
            "pull_request", "pull_request_target", 1))
        self.assertOneProblem("pull_request_target")

    def test_a_workflow_without_triggers_has_none(self):
        self.write(".github/workflows/w.yml", "jobs: {}\n")
        self.assertEqual(self.problems(), [])


class TestMalformedYaml(RepoCase):
    def test_invalid_yaml_is_reported(self):
        self.write(".github/workflows/w.yml", "on: [push\n")
        self.assertOneProblem("not valid YAML")

    def test_an_empty_file_is_reported(self):
        self.write(".github/workflows/w.yml", "")
        self.assertOneProblem("empty or not a mapping")

    def test_odd_jobs_and_steps_are_skipped(self):
        self.write(
            ".github/workflows/w.yml",
            "on: push\njobs:\n  a: just-a-string\n  b:\n    timeout-minutes: 1\n    steps:\n      - just-a-string\n",
        )
        self.assertEqual(self.problems(), [])

    def test_an_action_without_steps_passes(self):
        self.write("actions/a/action.yml", "runs:\n  using: node24\n  main: index.js\n")
        self.assertEqual(self.problems(), [])


class TestDocs(RepoCase):
    def test_an_em_dash_fails(self):
        self.write("docs/A.md", "One\nTwo \u2014 three\n")
        self.assertOneProblem("docs/A.md:2: em dash")

    def test_a_broken_link_fails(self):
        self.write("README.md", "See [the guide](docs/MISSING.md).\n")
        self.assertOneProblem("doesn't exist")

    def test_a_link_to_a_folder_passes(self):
        self.write("docs/records/0001.md", "# One\n")
        self.write("README.md", "See [records](docs/records/).\n")
        self.assertEqual(self.problems(), [])

    def test_a_link_to_a_missing_heading_fails(self):
        self.write("docs/A.md", "# Title\n\n## Settings applied by API\n")
        self.write("README.md", "[a](docs/A.md#settings-by-api)\n")
        self.assertOneProblem("heading that doesn't exist")

    def test_a_link_to_a_real_heading_passes(self):
        self.write("docs/A.md", "# Title\n\n## 4. Core `components`\n\n## Settings applied by API ##\n")
        self.write("README.md", "[a](docs/A.md#4-core-components) [b](docs/A.md#Settings-applied-by-API)\n")
        self.assertEqual(self.problems(), [])

    def test_repeated_headings_get_numbered_anchors(self):
        self.assertEqual(check_policy.heading_anchors("# Notes\n## Notes\n### Notes\n"), {"notes", "notes-1", "notes-2"})

    def test_an_anchor_in_the_same_file(self):
        self.write("A.md", "# Top\n\n[up](#top) [down](#nowhere)\n")
        self.assertOneProblem("heading that doesn't exist")

    def test_an_anchor_on_a_file_that_is_not_markdown_is_not_checked(self):
        self.write("x.yml", "a: 1\n")
        self.write("A.md", "[x](x.yml#L1)\n")
        self.assertEqual(self.problems(), [])

    def test_links_in_code_are_ignored(self):
        self.write("A.md", "Write ` Record: [N](docs/NNNN.md)`.\n\n```\n[x](missing.md)\n# not a heading\n```\n")
        self.assertEqual(self.problems(), [])

    def test_headings_in_code_make_no_anchors(self):
        self.assertEqual(check_policy.heading_anchors("```\n# Fake\n```\n# Real\n"), {"real"})

    def test_web_and_mail_links_are_not_checked(self):
        self.write("A.md", "[w](https://example.com/x.md) [m](mailto:x@example.com)\n")
        self.assertEqual(self.problems(), [])

    def test_skipped_folders_are_not_scanned(self):
        self.write(".terraform/modules/x/README.md", "[x](missing.md) \u2014\n")
        self.assertEqual(self.problems(), [])


class TestMain(RepoCase):
    def test_it_prints_problems_and_fails(self):
        self.write("A.md", "\u2014\n")
        out = io.StringIO()
        with redirect_stdout(out):
            self.assertEqual(check_policy.main(["check_policy.py", str(self.root)]), 1)
        self.assertIn("A.md:1: em dash", out.getvalue())

    def test_it_passes_quietly(self):
        out = io.StringIO()
        with redirect_stdout(out):
            self.assertEqual(check_policy.main(["check_policy.py", str(self.root)]), 0)
        self.assertEqual(out.getvalue(), "")

    def test_it_defaults_to_the_current_directory(self):
        with mock.patch.object(check_policy, "check_repo", return_value=[]) as check:
            self.assertEqual(check_policy.main(["check_policy.py"]), 0)
        self.assertEqual(check.call_args.args[0], Path(".").resolve())


class TestThisRepo(unittest.TestCase):
    def test_the_repo_follows_its_own_policy(self):
        self.assertEqual(check_policy.check_repo(REPO_ROOT), [])
