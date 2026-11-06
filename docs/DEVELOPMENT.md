# Development

How to work on yggdrasil.

## The loop

CI is the test runner. Branch off the latest `main`, open a draft PR early, push small commits, and read the checks. Run something locally only when CI can't answer the question, and then in Docker, never on the host.

Work in a fresh clone, never in a checkout someone else is using. Several sessions often run at once, and a shared checkout loses work to branch switches.

## Commands

Each target runs in a container from `compose.yml`, pinned by tag and digest, and CI runs the same targets. Record: [0018](architectural-decision-records/0018-checks-run-through-make-in-pinned-containers.md)

| Target | Does |
|---|---|
| `make test` | The whole suite under line and branch coverage, as the `test` job runs it |
| `make test-one MODULE=tests.test_check_policy` | One test module, for iterating on a failure |
| `make lint` | ruff under `ruff.toml`, as the `Lint` job runs it |
| `make actionlint` | actionlint over every workflow, as the `actionlint` job runs it |
| `make lock` | Not a check: rewrites `requirements-dev.txt` from `requirements-dev.in`, with hashes. A pin change ships with its new lock in the same PR |

`make coverage-summary` prints the coverage table as markdown; CI appends it to the run's summary.

## Tests

- **Action scripts** are Python, tested with `unittest` and `unittest.mock`. Coverage aims at every line and branch, without a floor: CI reports it, and a gap gets a test or a written reason. Tests never touch the network.
- **Workflows** are checked by `actionlint` and by the policy check, `scripts/check_policy.py`, over `.github/workflows/` and `actions/*/action.yml`. A new rule gets a test in `tests/test_check_policy.py` that writes a file breaking it. Record: [0019](architectural-decision-records/0019-a-policy-check-holds-workflows-and-docs.md)
- **Modules** each run through a test caller in yggdrasil's own CI, with the release module in `dry-run` (#4).
- **Terraform** uses `terraform test` with mock providers, tflint, and the Trivy config scan (#8).

## Writing docs and records

Every change updates the page that owns its topic, in the same PR, and every decision gets a record in [architectural-decision-records/](architectural-decision-records/README.md). No doc contains an em dash. Record: [0017](architectural-decision-records/0017-docs-and-records.md)
