# 0016. PR plans run with the App's full token for now

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05: "Accepted for now, but add an issue… tagged security."
- Issues and PRs: #8, #13
- Cited in code as: none
- Guide: [`docs/PRD.md`](../PRD.md), "Settled at sign-off" item 6

## Context

`terraform plan` on a PR needs to read every managed repo's settings. The only App that can do that, `zimmertr-yggdrasil-bot`, can also change them.

## Decision

Plans on PRs mint their token from `zimmertr-yggdrasil-bot`, with its full permissions. #13 tracks a second, read-only App for plans.

## Evidence

No dated measurement. Which read scopes the GitHub provider needs is not yet known; #3 finds out.

## Alternatives rejected

- A read-only plan App from the start: one more key to store and audit, before anyone knows which scopes a plan needs.

## Consequences

Every plan job holds a token that could change any managed repo. Only TJ can push branches here and forks get no secrets (0010), so the exposure is a compromised action or dependency running inside a plan job.
