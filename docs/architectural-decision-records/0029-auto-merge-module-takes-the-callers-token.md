# 0029. The auto-merge module takes each caller's own merge token, not the App's key

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on #4 item 2.7, choosing "Each repo's own PAT" over storing the App key in every repo
- Issues and PRs: #4, #30
- Cited in code as: decision record 0029, in `.github/workflows/auto-merge.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#auto-mergeyml)

## Context

The merge must be armed with a token other than `GITHUB_TOKEN`, or the merged update starts no `on: push` workflow and never releases. yggdrasil mints a token from `zimmertr-yggdrasil-bot` (0021), but the App has admin on every repo it's installed on.

## Decision

- The module takes a required `merge-token` secret. hevy-trainer-sync and Bluebird pass their `AUTO_MERGE_PAT`, a Dependabot secret they already hold.
- yggdrasil keeps its own `dependabot-auto-merge.yml`, which mints the App token.
- No `update-types` input: every caller takes patch and minor today.

## Evidence

- 2026-11-05: hevy-trainer-sync's and Bluebird's workflows arm the merge with `AUTO_MERGE_PAT` and take patch and minor.

## Alternatives rejected

- The App's private key as a Dependabot secret in every repo: one bot identity (0007), but a key leaked from any one repo would give admin on all of them.

## Consequences

Each repo keeps its own PAT to rotate (#12). The module only runs on Dependabot's PRs, so yggdrasil has no test caller for it; actionlint and zizmor check it, and #5 is its first real run.
