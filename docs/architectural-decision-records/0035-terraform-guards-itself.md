# 0035. The github stack guards itself with typed variables, preconditions and `archive_on_destroy`, with no schema, profile files or destroy label

- Status: Accepted. Supersedes 0011's schema and destroy gate, and 0012's profiles. Superseded in part by 0043
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, on the end-to-end audit after #4: "Rewrite #8 to native TF"
- Issues and PRs: #8
- Cited in code as: none yet; #8 builds it
- Guide: [`docs/PRD.md`](../PRD.md), requirements 11 and 12

## Context

#8 planned four custom pieces around Terraform: JSON Schemas for the repo, org and profile files, profile files, a `Config Policy` check, and a Python plan guard that failed a destroy without a `destroy-approved` label and sent a weakening apply to a reviewer environment. Terraform and the GitHub provider already do each of these, and TJ reads every plan in its PR before merging.

## Decision

- **Defaults, not profiles.** `terraform/github/` holds `initialize-project`'s standard settings as defaults. A repo file sets only what differs, such as `archived: true`.
- **Typed variables, not a schema.** The repo and org modules type their inputs, with `optional()` defaults, so a wrong value fails `terraform validate` and the plan.
- **Preconditions, not a policy check.** The repo module's preconditions fail the plan for a file that turns off branch protection or a security feature, except where GitHub can't apply one (private or archived repos). Weakening a setting means changing a precondition, in a PR TJ reviews.
- **`archive_on_destroy`, not a label.** Every repo sets it, so removing a repo's file archives the repo. A `removed` block with `destroy = false` stops managing one without touching it. Every other destroy shows in the plan comment.
- **No reviewer environment for applies.** Every apply follows a merge TJ okayed. Dependabot's Terraform provider bumps wait for TJ instead of merging themselves, so no apply runs on a plan nobody read.

## Evidence

No dated measurement. `archive_on_destroy` was already in #8's plan for `github_repository` (item 6.4).

## Alternatives rejected

- The schema, profile files, `Config Policy` and `scripts/plan_guard.py`, as planned: four custom pieces for what Terraform does natively, and the plan guard would have been Python (0026).

## Consequences

#8 drops items 6.3's schemas and profiles and 6.7's plan guard, and the `terraform-approval` environment. Moving a repo off classic branch protection no longer needs a label: the plan comment shows the delete.
