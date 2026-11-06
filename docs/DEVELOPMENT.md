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
| `make actionlint` | actionlint over every workflow, in the image the lint module's `actionlint` job uses |
| `make zizmor` | zizmor's pedantic audits, in the image the lint module's `zizmor` job uses. Set `GH_TOKEN` (for example `GH_TOKEN=$(gh auth token) make zizmor`) for the online audits, which include the version comment checks; without it zizmor runs offline and skips them |
| `make semgrep` | Semgrep's base-image digest rule over every Dockerfile, in the image the lint module's `semgrep` job uses |
| `make docs` | lychee over every relative link and anchor, and the em dash grep, as the `Docs` job runs them |
## Tests

- **Workflows and actions** are checked by actionlint and zizmor. Before adding a check of our own, look for a maintained tool that does it. Record: [0019](architectural-decision-records/0019-community-tools-hold-workflows-and-docs.md)
- **Modules** each run through a test caller in yggdrasil's own CI, with the release module in `dry-run` (#4). Their steps are shell, `jq` and `yq`, with no unit tests of their own. Record: [0026](architectural-decision-records/0026-modules-carry-only-what-callers-use.md)
- **Terraform** uses `terraform test` with mock providers, tflint, and the Trivy config scan (#8).

## Writing docs and records

Every change updates the page that owns its topic, in the same PR, and every decision gets a record in [architectural-decision-records/](architectural-decision-records/README.md). No doc contains an em dash. Record: [0017](architectural-decision-records/0017-docs-and-records.md)
