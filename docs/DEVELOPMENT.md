# Development

How to work on yggdrasil.

## The loop

CI is the test runner. Branch off the latest `main`, open a draft PR early, push small commits, and read the checks. Run something locally only when CI can't answer the question, and then in Docker, never on the host.

Work in a fresh clone, never in a checkout someone else is using. Several sessions often run at once, and a shared checkout loses work to branch switches.

## Commands

Each target runs in a container from `compose.yml`, pinned by tag and digest, and CI runs the same targets. Record: [0018](architectural-decision-records/0018-checks-run-through-make-in-pinned-containers.md)

| Target | Does |
|---|---|
| `make check` | Every check below |
| `make actionlint` | actionlint over every workflow, as the `actionlint` job runs it |
| `make shellcheck` | shellcheck over every shell script in `SHELL_SCRIPTS`, also in the `actionlint` job |
| `make zizmor` | zizmor's pedantic audits, as the `zizmor` job runs it. Set `GH_TOKEN` (for example `GH_TOKEN=$(gh auth token) make zizmor`) for the online audits, which include the version comment checks; without it zizmor runs offline and skips them |
| `make docs` | lychee over every relative link and anchor, and the em dash grep, as the `Docs` job runs them |
| `make gitversion` | `tests/gitversion/test.sh` in the pinned GitVersion image, as the `GitVersion Engine` job runs it |

The Python harness (a hashed lock, ruff, coverage and a `test` job) arrives with the first Python code, in #4.

## Tests

- **Action scripts** (#4) are Python, tested with `unittest` and `unittest.mock`. Coverage aims at every line and branch, without a floor: CI reports it, and a gap gets a test or a written reason. Tests never touch the network.
- **Version rules** are checked by `tests/gitversion/test.sh`: each case builds a fresh made-up history, one commit a minute, and checks the `SemVer` GitVersion gives and the commit its `Sha` names. A change to `GitVersion.yml` or `defaults/GitVersion.yml` adds or edits a case. Record: [0025](architectural-decision-records/0025-gitversion-tested-in-its-own-image.md)
- **Workflows and actions** are checked by actionlint and zizmor. Before adding a check of our own, look for a maintained tool that does it. Record: [0019](architectural-decision-records/0019-community-tools-hold-workflows-and-docs.md)
- **Modules** each run through a test caller in yggdrasil's own CI, with the release module in `dry-run` (#4).
- **Terraform** uses `terraform test` with mock providers, tflint, and the Trivy config scan (#8).

## Writing docs and records

Every change updates the page that owns its topic, in the same PR, and every decision gets a record in [architectural-decision-records/](architectural-decision-records/README.md). No doc contains an em dash. Record: [0017](architectural-decision-records/0017-docs-and-records.md)
