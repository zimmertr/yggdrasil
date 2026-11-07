# 0016. PR plans run with the App's full token for now

- Status: Superseded by [0044](0044-pr-plans-run-through-dflook-with-read-only-tokens.md)
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

2026-11-05 (#3): every plan ran with the App's full token, so which read scopes a plan needs is still not known. #13 finds out when it builds the read-only App.

## Alternatives rejected

- A read-only plan App from the start: one more key to store and audit, before anyone knows which scopes a plan needs.

## Consequences

Every plan job holds a token that could change any managed repo. Only TJ can push branches here and forks get no secrets (0010), so the exposure is a compromised action or dependency running inside a plan job.
