# 0047. PR plans use the same write tokens as the apply, because a read-only token can't see a repo's merge settings

- Status: Accepted. Supersedes 0044 in part: the read-only tokens
- Date: 2026-11-07
- Decider: TJ, 2026-11-07, in #8, after the first real apply refused: "Yes", to giving plans the apply's write tokens.
- Issues and PRs: #8, #13, #51
- Cited in code as: decision record 0047, in `.github/workflows/terraform-github.yml`
- Guide: [`docs/CICD.md`](../CICD.md), the PR checks

## Context

[0044](0044-pr-plans-run-through-dflook-with-read-only-tokens.md) gave PR plans tokens with Administration and Contents read only, and [0045](0045-merges-apply-through-dflook.md) applies on merge only when main's plan, made with write tokens, matches the PR's comment. #51's merge was the first apply with anything in it, and it refused.

## Decision

- Every token step asks for Administration and Contents write, on a PR and on main alike.
- Everything else in 0044 stands: plans run only on this repo's own branches and Dependabot's, never on a fork's, and never on `pull_request_target`.

## Evidence

- 2026-11-07, #51's merge: `dflook/terraform-apply` printed "Not applying the plan - it has changed from the plan on the PR". In its diff, the PR's plan read each `.github` repo's `allow_merge_commit` and `allow_rebase_merge` as `false` and `squash_merge_commit_title` as absent, and main's plan read `true`, `true` and `COMMIT_OR_PR_TITLE`. Nothing was applied, and HCP's state didn't change.
- 2026-11-07: `gh api repos/zimmertr/.github`, as TJ, returned `allow_merge_commit: true`, `allow_rebase_merge: true` and `squash_merge_commit_title: COMMIT_OR_PR_TITLE`, matching main's plan. So GitHub left those fields out of what it returned to the read-only token.

## Alternatives rejected

- Read-only plans with `auto_approve: true` on the apply: it would apply changes no comment showed.
- A second, read-only App (#13's option A): its tokens would hide the same fields, so its plans would be just as wrong.

## Consequences

- Every plan job holds tokens that could change any managed repo, which is 0016's exposure: a compromised action or dependency in that job. Only TJ and Dependabot push branches here, and forks get no secrets.
- #13's read-only App can't fix this, and the issue says so.
