# 0044. PR plans run through dflook/terraform-plan, with read-only tokens

- Status: Accepted. Supersedes 0016, and 0018 in part
- Date: 2026-11-07
- Decider: TJ, 2026-11-07, in #8: on step 6.5, read-only tokens for plans and no required check ("Okay, continue"); on how the plan runs, "dflook actions", the recommended option.
- Issues and PRs: #8, #13
- Cited in code as: decision record 0044, in `.github/workflows/terraform-plan.yml`
- Guide: [`docs/CICD.md`](../CICD.md), the PR checks

## Context

#8 step 6.5 plans the github stack on every PR that can change it, so TJ reads each settings change before merging. The stack needs one installation token per owner, since a token reaches one owner only, and HCP Terraform for its state. 0016 had plans use the App's full permissions until #13 found out which a plan needs. The plan also has to be posted on the PR, and step 6.8's apply on merge has to apply what that plan showed.

## Decision

- `.github/workflows/terraform-plan.yml` runs on PRs that touch `terraform/`, `repos/` or `orgs/`, from this repo's own branches only, and not on Dependabot's, which can't read Actions secrets. It isn't a required check: a path-filtered check never reports on other PRs.
- It mints six tokens from `zimmertr-yggdrasil-bot`, one per owner, each with Administration and Metadata read only, and passes them as `github_tokens`. Nothing new is stored: the job holds the same `YGGDRASIL_BOT_PRIVATE_KEY` and `TF_API_TOKEN` as before.
- `dflook/terraform-plan` runs the plan and keeps one comment on the PR up to date. Its sibling `dflook/terraform-apply` applies on merge only when the plan still matches that comment (6.8).
- The action runs in its own image and takes Terraform's version from the HCP workspace `github`, then from `required_version`, not from `compose.yml` (0018 in part).

## Evidence

- 2026-11-07: dflook's README for `terraform-plan` v3.1.2: one comment per PR, updated by each run; `TERRAFORM_CLOUD_TOKENS` for HCP; `TERRAFORM_ACTIONS_GITHUB_TOKEN` keeps the comment token apart from the github provider's `GITHUB_TOKEN`. Its image is pinned by digest in `action.yaml`.
- 2026-11-07: `terraform-version`'s README: the version comes first from the cloud workspace, then from `required_version`, using the newest version that matches a range. On #49 it chose Terraform 1.17.1 from `required_version`.
- 2026-11-07, on #49: with no `hostname` in the `cloud` block, the action's `terraform init` failed with `failed to create backend alias to target ""`, and with the default `workspace` input, with `Specified workspace "name" conflicts with TF_WORKSPACE`. `hostname = "app.terraform.io"` and `workspace: github` fixed both. The next run failed with `Terraform failed to find workspace "github"`: the workspace had never been made, and the action's init only selects one. With TJ's okay, the `github` workspace was created through HCP's API, in local execution mode with Terraform 1.17.1. The rerun said "Using remote workspace terraform version, which is set to 1.17.1", planned with every token shown as `(sensitive value)`, and posted the comment.

## Alternatives rejected

- Our own steps (`terraform plan` in the `compose.yml` image, then a comment action): the same Terraform version everywhere, but shell to format the plan, and 6.8 would need its own check that the applied plan is the one TJ read.
- A second, read-only App (#13's option A): one more key to store and rotate. A narrowed token stops a plan from writing, though the key in the job still could mint a full one.
- Full-permission tokens (0016): a plan reads, so it has no use for write.

## Consequences

- Until 6.9 imports the first repos, the stack manages nothing and the plan is "No changes", so the read-only permissions are first tested by the first import batch's plan. A missing permission fails that plan, and the fix is one more `permission-*` line in each token step.
- Dependabot's provider bumps get no plan comment. TJ reviews them without one, or the plan runs on them once `TF_API_TOKEN` is also a Dependabot secret.
- Terraform's version for plan and apply follows the HCP workspace's setting, which Dependabot doesn't move. A bump of the `compose.yml` image changes the checks, not the plan, until someone sets the workspace to match.
- Each new stack needs its workspace created by hand before its first plan, with its Terraform version set.
