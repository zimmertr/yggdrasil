# 0045. A merge applies the github stack through dflook/terraform-apply, only when the plan still matches the PR's comment

- Status: Accepted. Supersedes 0044 in part: its workflow is now `terraform-github.yml`. Superseded in part by [0047](0047-pr-plans-use-the-applys-write-tokens.md): the plan's tokens are write too, and by [0048](0048-imports-apply-by-hand.md): an import applies by hand
- Date: 2026-11-07
- Decider: TJ, 2026-11-07, in #8, on step 6.8's plan: one workflow for plan and apply, write tokens on main only, applies that queue, and a new PR when an apply refuses ("Yes").
- Issues and PRs: #8, #50
- Cited in code as: decision record 0045, in `.github/workflows/terraform-github.yml`
- Guide: [`docs/USAGE.md`](../USAGE.md), when an apply refuses

## Context

0008 settled plan on PR, apply on merge. 0044 put the plan in a PR comment through `dflook/terraform-plan`, chosen partly because its sibling applies only what that comment shows. The apply needs write tokens for all six owners, and must never run two at once or apply a plan nobody read.

## Decision

- `.github/workflows/terraform-github.yml` replaces `terraform-plan.yml` and runs on PRs and on pushes to main that touch `terraform/`, `repos/` or `orgs/`. One job: on a PR it plans, on main it applies. The six token steps are written once and ask for Administration read on a PR and write on main.
- `dflook/terraform-apply` plans again on main and applies only when that plan matches the merged PR's comment. Otherwise it fails and changes nothing. The plan and apply steps take their inputs from one YAML anchor, since the apply must get the same ones.
- Applies share one concurrency group and are never cancelled. PR plans still replace each other.
- When an apply refuses, the fix is a new PR, whose plan shows what is left to apply. There is no manual apply.

## Evidence

- 2026-11-07: dflook's README for `terraform-apply` v3.1.2: on `push`, the commit must come from a PR; the plan comment must be by the same token's author; `failure_reason` is `plan-changed` when the approved plan no longer matches.
- 2026-11-07: GitHub's workflow syntax takes YAML anchors and aliases, but not merge keys (`<<:`), so each token step keeps its full `with:` block.

## Alternatives rejected

- A second workflow for the apply: the six token steps copied, about 60 lines, that would drift.
- `auto_approve: true`: applies whatever main plans, including changes nobody read.
- Applying the saved plan file from the PR run: the file holds the tokens it was planned with, would have to be stored, and goes stale when another PR merges first.
- A manual apply on `workflow_dispatch`: a way to apply a plan no PR showed.

## Consequences

- Two Terraform PRs merged close together: the second one's apply refuses, because main's plan now includes the first one's changes. Its changes wait for a new PR.
- Administration write is untested until the first import batch (6.9) applies. A missing permission fails that apply, and the fix is one more `permission-*` line, which raises the plan's tokens too.
- Until 6.9, the stack manages nothing, so the first apply writes only the empty `repos` output to state.
