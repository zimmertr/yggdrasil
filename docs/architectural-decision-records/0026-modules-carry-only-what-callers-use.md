# 0026. The modules carry only what hevy-trainer-sync and Bluebird use today, in shell, `jq` and `yq`, with no Python

- Status: Superseded in part by 0037
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on #4's plan: "Merge and Proceed with trimming things we don't need. YAGNI and KISS."
- Issues and PRs: #4
- Cited in code as: none
- Guide: [`docs/DEVELOPMENT.md`](../DEVELOPMENT.md#tests)

## Context

#4's plan carried a Python test setup, four composite actions with their own tests, and an `actionlint` module. Each copied something hevy-trainer-sync or Bluebird does in a few lines today.

## Decision

- No Python, so no Python test setup. A community action checks PR titles (0020), `jq` counts Trivy's Critical and High findings, and `yq` sets the deploy tag or the chart's `appVersion`.
- The release guards and the Trivy count stay shell steps inside the modules that use them, as they are in hevy-trainer-sync and Bluebird today. No composite action until two modules need the same step.
- No `actionlint` module. It is one step, and each repo runs it already, pinned by its own Dependabot.
- A module's steps are tested by running the module through a test caller in yggdrasil's CI, not by unit tests.

## Evidence

- 2026-11-05: Bluebird's `trivy-crit-high` action is one `jq` expression. hevy-trainer-sync's `bump_manifest_tag.py` is 50 lines that change one `newTag` line, with 101 lines of tests.

## Alternatives rejected

- Porting the Python scripts with full coverage: about 150 lines of code and tests for what `yq` does in one command.

## Consequences

`yq` may reformat more of a file than the one line it sets. #4 item 2.13 tries it on a copy of the real Kubernetes-Manifests file first.
