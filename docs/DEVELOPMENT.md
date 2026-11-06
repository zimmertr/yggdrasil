# Development

How to work on yggdrasil.

## The loop

CI is the test runner. Branch off the latest `main`, open a draft PR early, push small commits, and read the checks. Run something locally only when CI can't answer the question, and then in Docker, never on the host.

Work in a fresh clone, never in a checkout someone else is using. Several sessions often run at once, and a shared checkout loses work to branch switches.

## Commands

The `make` targets arrive with #2 item 0.4: `make test`, `make lint`, `make actionlint` and `make lock`. Each runs in a container pinned by tag and digest, and CI runs the same targets.

## Tests

- **Action scripts** are Python, tested with `unittest` and `unittest.mock`. Coverage aims at every line and branch, without a floor: CI reports it, and a gap gets a test or a written reason. Tests never touch the network.
- **Workflows** are checked by `actionlint` and by a policy test over `.github/workflows/` and `actions/*/action.yml` (#2 item 0.5).
- **Modules** each run through a test caller in yggdrasil's own CI, with the release module in `dry-run` (#4).
- **Terraform** uses `terraform test` with mock providers, tflint, and the Trivy config scan (#8).

## Writing docs and records

Every change updates the page that owns its topic, in the same PR, and every decision gets a record in [architectural-decision-records/](architectural-decision-records/README.md). No doc contains an em dash. Record: [0017](architectural-decision-records/0017-docs-and-records.md)
