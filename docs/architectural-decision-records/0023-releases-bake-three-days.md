# 0023. Every consumer is production: each takes a release once it is three days old, and patch and minor bumps merge themselves

- Status: Accepted. Supersedes 0005
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on rollout rings: "We're treating some repos as more important than others? That's not right. Everything is production here." On a bump that can't merge itself: "If it's blocked it's blocked." Then, after #3 found Dependabot's default cooldown: "We can wait 3 days before updating dependencies… Giving things time to bake is a good idea. We're not in a hurry."
- Issues and PRs: #1, #3, #5, #6, #7
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "Every repo is production"

## Context

0005 had every consumer take a release the day it shipped. #3 found that Dependabot holds a version back for three days even when `dependabot.yml` sets no `cooldown`, so "the day it ships" was never what Dependabot did.

## Decision

Every consumer checks for yggdrasil releases daily and takes a release once it is three days old. A Dependabot consumer sets `cooldown: default-days: 3` in `dependabot.yml`, rather than leaning on Dependabot's unstated default. A Renovate consumer sets `minimumReleaseAge: "3 days"` or longer. Patch and minor bumps merge themselves once the consumer's checks pass; a major waits for TJ. A bad release is fixed forward with the next patch.

No repo goes first: every consumer waits the same three days.

## Evidence

- 2026-11-05 (#3): with no `cooldown` set, Dependabot logged "Days since release : 1 (cooldown days 3)" and opened no PR. With `default-days: 0` it opened the PR on the next run. [`docs/DATA.md`](../DATA.md#github)
- 2026-11-05: Kubernetes-Manifests' Renovate config merges minor and patch updates once they are seven days old (`minimumReleaseAge`), which already waits longer than three.

## Alternatives rejected

- No cooldown, the day a release ships (0005): a broken release reaches every consumer within a day, before anyone has used it.
- Rollout rings, with canary repos first: they rank repos, and TJ treats every repo as production.

## Consequences

A fix also takes three days to arrive, unless TJ merges the bump by hand. The test callers and the release `dry-run` in yggdrasil's own CI (#4) stay the first guard against a bad release.

0005 expected a bump that edits `.github/workflows` to wait for TJ, because `AUTO_MERGE_PAT` has no Workflows permission. In #3, `GITHUB_TOKEN`, which never has that permission, merged such a bump, so the PAT likely can too. The first such bump in a consumer confirms it.
