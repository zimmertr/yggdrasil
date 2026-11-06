# 0039. A private repo runs the shared checks without requiring them, and has no auto-merge, while TJ's account is on GitHub Free

- Status: Accepted
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, in #7, choosing to run the checks without requiring them over GitHub Pro or leaving the private repos out
- Issues and PRs: #7
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "A private repo requires nothing"

## Context

The baseline requires `PR Title` and the three `Lint /` checks, and Dependabot's patch and minor updates merge themselves once the required checks pass. GitHub Free offers neither branch protection nor rulesets on a private repo, so nothing can be required there, and an armed auto-merge would have nothing to wait for.

## Decision

- A private repo calls the same modules as a public one, and their checks run and report on every PR.
- Nothing is required, and the repo has no `auto-merge` caller, so its Dependabot PRs wait for TJ.
- This holds while the account is on GitHub Free. On a paid plan, the private repos take the full baseline.
- Resume is the only private repo in scope.

## Evidence

- 2026-11-06, #7's inventory: `GET repos/zimmertr/{Email-Infrastructure,Resume}/branches/main/protection` and `.../rulesets` both answered 403, "Upgrade to GitHub Pro or make this repository public to enable this feature." Both repos had `allow_auto_merge` off. Turning it on wasn't tried.

## Alternatives rejected

- GitHub Pro: a paid plan for one private repo's checks.
- Leaving the private repos out of the baseline: their workflows would go unlinted and their actions unbumped.

## Consequences

A red check in Resume doesn't block a merge, so TJ reads its checks before merging. #8's preconditions need the same exception for private repos.
