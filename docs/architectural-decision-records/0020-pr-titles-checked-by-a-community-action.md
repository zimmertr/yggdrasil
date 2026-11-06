# 0020. PR titles are checked by action-semantic-pull-request, against the same types GitVersion reads

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, choosing the action over a port of hevy-trainer-sync's `check_pr_title.py`: "Yes, I agree regarding the action."
- Issues and PRs: #2, #19
- Cited in code as: decision record 0020, in `.github/workflows/pr-title.yml`
- Guide: [`docs/CICD.md`](../CICD.md), PR checks

## Context

The squash commit's title is the PR title, and GitVersion picks every module's next version from that line alone (0004). A title it can't read still releases, as a patch, so a mistyped breaking change would ship as a patch to twenty repos. Bluebird and hevy-trainer-sync guard this with a custom script that reads `GitVersion.yml`'s patterns.

## Decision

- `.github/workflows/pr-title.yml` runs `amannn/action-semantic-pull-request`, pinned by SHA, as the job `PR Title`, on `pull_request` (opened, edited, reopened, synchronize) with only `pull-requests: read`.
- Its `types` list is exactly the types in `GitVersion.yml`'s three patterns: `feat`, `fix`, `perf`, `refactor`, `chore`, `docs`, `style`, `test`, `ci` and `build`. A change to one changes the other in the same PR.
- A `!` before the colon marks a breaking change, which both the action and GitVersion read.
- `GitVersion.yml` is hevy-trainer-sync's, with its seed of `v0.1.0` for the first release.

## Evidence

- 2026-11-05: the action's README documents `!` for breaking changes in a single-line title, and a `types` list of regex patterns.

## Alternatives rejected

- Porting `check_pr_title.py` with its tests: it reads the patterns from `GitVersion.yml`, so the two can't disagree, but it is custom code that the action already does (0019).
- `pull_request_target`, which the action's README suggests so fork PRs can be checked: it runs with this repo's secrets (0010).

## Consequences

The type list lives in two files, held together by the comments in each. The action is stricter than GitVersion: it needs a space after the colon, and it matches types case-sensitively, so `Fix: x` fails the check even though GitVersion would read it.
