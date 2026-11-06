# 0014. yggdrasil's own settings are set by API now and imported into Terraform in #8

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05. Asked "Why are we making changes manually instead of with terraform?", then, after the reasons below: "Fair enough", and okayed the calls.
- Issues and PRs: #2, #8
- Cited in code as: none
- Guide: [`docs/CICD.md`](../CICD.md), Settings applied by API

## Context

yggdrasil needs its settings and branch protection before any PR can be trusted, but the Terraform that will manage them needs yggdrasil's CI, an environment holding the App's key, and the HCP workspace first.

## Decision

The foundation's settings are API calls that TJ okays one change at a time, each logged with its exact command in [`docs/CICD.md`](../CICD.md#settings-applied-by-api). #8 imports yggdrasil like every other repo, and its plan must come back empty against that log.

## Evidence

- 2026-11-05: the calls in #2 item 0.1 were applied and each setting read back from its endpoint.

## Alternatives rejected

- A small Terraform stack for yggdrasil alone in #2, run from TJ's machine in Docker: it moves the HCP and provider work ahead of the CI it depends on, and runs with TJ's own credentials, the hand-run setup this project replaces.

## Consequences

Until #8, a settings change needs TJ's okay and a new entry in the log. If the GitHub provider can't manage a setting (immutable releases, private vulnerability reporting and `sha_pinning_required` are not yet checked), it stays a logged API call after #8 too.
