# 0048. An import applies when TJ starts the apply by hand, because an import's plan never matches its comment

- Status: Accepted. Supersedes 0045 in part: there is now a manual apply
- Date: 2026-11-07
- Decider: TJ, 2026-11-07, in #8: "1", a manual apply over a script that compares the two plans without their `etag` lines.
- Issues and PRs: #8, #51, #52
- Cited in code as: decision record 0048, in `.github/workflows/terraform-github.yml`
- Guide: [`docs/USAGE.md`](../USAGE.md), when an apply refuses

## Context

[0045](0045-merges-apply-through-dflook.md) applies a merge only when main's plan matches the PR's comment, and has no manual apply. #52's merge, the first with write tokens on both sides, still refused to apply #51's six `.github` imports.

## Decision

- `terraform-github.yml` also runs on `workflow_dispatch`, from main only. Started by hand, its `Apply github` job runs `dflook/terraform-apply` with `auto_approve: true`: it plans on main and applies that plan, with no comment to match.
- TJ starts it only after a merge's apply refused on an import, having read that PR's plan.
- Every other change still applies only when the plans match.

## Evidence

- 2026-11-07, #52's merge: "Not applying the plan - it has changed from the plan on the PR". The only differences were each imported repo's `etag`, as `W/"..."` values that differed between the PR's plan and main's.
- 2026-11-07: Terraform prints every attribute of a resource it imports, so `etag` shows in an import's plan. For a resource already in state, it hides unchanged attributes. `integrations/github` suppresses changes to `etag` (integrations/terraform-provider-github#2840) but can't keep it out of an import's plan. `dflook/terraform-github-actions`' `cmp.py` drops only the "unchanged attributes hidden" lines before it compares.

## Alternatives rejected

- A script that compares the two plans without their `etag` lines and applies if the rest matches: custom shell to keep up.
- `auto_approve: true` on every apply: changes nobody read could apply.

## Consequences

- An import's PR merges, its apply refuses, and TJ starts the apply from the Actions tab. That's 6.17 now, then 6.9 to 6.13.
- A hand-started apply applies whatever main plans at that moment. If another Terraform PR merged in between, its changes apply too.
