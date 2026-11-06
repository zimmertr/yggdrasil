# 0005. Every consumer is production: each takes a release the day it ships, and patch and minor bumps merge themselves

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on rollout rings: "We're treating some repos as more important than others? That's not right. Everything is production here." On a cooldown: "Why not get updates immediatly/daily?" On a bump that can't merge itself: "If it's blocked it's blocked."
- Issues and PRs: #1, #5, #6, #7
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "Every repo is production"

## Context

The plan proposed rollout rings: a release reaching a few repos first, and the rest after a cooldown. TJ rejected ranking repos.

## Decision

Every consumer checks for yggdrasil releases daily, with no cooldown. Patch and minor bumps merge themselves once the consumer's checks pass; a major waits for TJ. A bad release is fixed forward with the next patch.

## Evidence

No dated measurement.

## Alternatives rejected

- Rollout rings, with canary repos first: they rank repos, and TJ treats every repo as production.
- A weekly check with a cooldown: slower fixes, and yggdrasil's own CI already tests each module through a caller before release.

## Consequences

A broken release reaches every consumer within a day, so the test callers and the release `dry-run` in yggdrasil's own CI (#4) are what stop it. Until #12 replaces `AUTO_MERGE_PAT`, a bump that edits `.github/workflows` may wait for TJ, because that token has no Workflows permission.
