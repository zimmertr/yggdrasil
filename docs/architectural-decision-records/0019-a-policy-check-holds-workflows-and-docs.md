# 0019. A policy check in the test suite holds every workflow, action and doc to the repo's rules

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, signing off the build plan on 2026-11-05; the rules are #2 item 0.5.
- Issues and PRs: #2
- Cited in code as: decision record 0019, in `scripts/check_policy.py` and `tests/test_check_policy.py`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Working in this repo

## Context

yggdrasil's workflows become every consumer's workflows (0005), so a weak pattern here spreads to twenty repos. Review alone misses an unpinned action or an expression pasted into a shell.

## Decision

`scripts/check_policy.py` runs inside the `test` job, through `tests/test_check_policy.py`, and fails the PR on any of these:

- a `uses:` that isn't a full commit SHA with a `# vX.Y.Z` comment, a local `./` path, or a `docker://` image pinned by digest;
- `${{ }}` inside `run:`, because the expression is pasted into the shell before it runs;
- a job without `timeout-minutes` (a job that calls a reusable workflow is exempt, because GitHub doesn't allow the key there);
- an `actions/checkout` without `persist-credentials: false`, outside `CHECKOUT_KEEPS_CREDENTIALS`, where each exception carries its reason;
- any `pull_request_target` (0010);
- a relative link in a `*.md` file, or its heading anchor, that doesn't resolve;
- an em dash in a `*.md` file (0017).

Each rule has a test that writes a file breaking it, and one test runs the check over the repo itself.

## Evidence

- 2026-11-05: the suite's first CI run passed, with 99% line and branch coverage of the script; the two gaps were closed in the same PR.

## Alternatives rejected

- A separate CI job for the policy: the `test` job already runs it, and one fewer required check is one fewer name to keep in branch protection.
- Leaving SHA pins to the repo setting `sha_pinning_required`: it refuses a tag, but not a SHA without its version comment, which Dependabot and a reader both need.

## Consequences

A workflow that needs an exception adds itself to `CHECKOUT_KEEPS_CREDENTIALS` with its reason, in the PR that needs it. The link check skips code spans and fenced blocks, so an example path in backticks never fails.
