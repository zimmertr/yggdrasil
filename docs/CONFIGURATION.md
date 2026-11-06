# Configuration

Every setting yggdrasil depends on, and where each is set. The repo's own settings are logged in [CICD.md](CICD.md#settings-applied-by-api), and its secrets are listed there too.

## Module inputs

None yet. Each module documents its inputs here when #4 adds it: the name, whether it is required, its default, and what it changes. A caller passes all of its configuration this way. Record: [0002](architectural-decision-records/0002-callers-bring-their-own-config.md)

## Shared defaults

A module reads these at the commit its caller pinned, by checking out `job.workflow_repository` at `job.workflow_sha`, and a caller can pass its own file instead. Records: [0006](architectural-decision-records/0006-shared-conventions-ship-as-defaults.md), [0022](architectural-decision-records/0022-modules-load-their-own-files-from-the-job-context.md)

| File | Sets |
|---|---|
| `defaults/GitVersion.yml` | yggdrasil's own `GitVersion.yml` without its `ignore` rule, so every merge to a caller's main releases. A first release is v0.1.0, and a repo already tagged counts from its last tag. `feat` is a minor, `!` before the colon a major, every other type a patch, and only the title counts |
| `defaults/trivy.yaml` | Skips pip's vendored SBOM, `**/pip/_vendor/bom.cdx.json`, which Trivy otherwise reads as installed packages at versions that aren't installed |
## The App

`zimmertr-yggdrasil-bot`, checked with `gh api apps/zimmertr-yggdrasil-bot` on 2026-11-05. Record: [0007](architectural-decision-records/0007-one-bot-identity.md)

- **App ID**: 5636772. **Client ID**: `Iv23liwzT6dq3xtbxm5P`, which `actions/create-github-app-token` takes as `client-id`. Neither is a secret. Owned by `zimmertr`, installable on any account, no webhook.
- **Installed on**: `zimmertr` (all repositories), and the orgs Bluebird-Forecast, Fellfield-Game, GPX-Search, TJs-Kubernetes-Service and Lakebagger. TJ installs it on any new owner, because a token minted for one owner can't write to another.
- **Repository permissions**: Actions, Administration, Contents, Environments, Pull requests and Workflows (read and write); Metadata (read).
- **Organization permissions**: Administration (read and write); Members (read).

A permission change takes effect on an owner only after that owner accepts it in its installation settings.

These permissions are the final list. In #3 they covered creating a repo from a template, every repo setting below, and merging a PR that edits workflows; nothing else was needed. Org settings were not exercised, so the org permissions stay as they are until #8 manages an org. [DATA.md](DATA.md#github) has the evidence.

## Terraform

The stacks use HCP Terraform org `Yggdrasil-Org` for state and locks, in local execution mode: plans and applies run in Actions, not on HCP. Record: [0008](architectural-decision-records/0008-terraform-plan-on-pr-apply-on-merge.md)

`repos/<name>.yml`, `orgs/<name>.yml`, the profiles and their schemas arrive with #8, and their fields are documented here then. Record: [0012](architectural-decision-records/0012-one-file-per-repo-and-org.md)

### What Terraform manages

Each setting `initialize-project` gives a new repo (its `repo.md` and `security.md`), and the resource that holds it. The pins are `integrations/github` 6.13.0, `Mastercard/restapi` 3.0.0 and `docker/docker` 0.7.0. "Tested" means #3 applied it with the App's token and a second plan found nothing to change ([DATA.md](DATA.md#github)). Record: [0024](architectural-decision-records/0024-terraform-providers-and-new-repos.md)

| Setting | Resource and attributes | Tested |
|---|---|---|
| A new repo | `github_repository` with a `template` block | yes |
| Squash merge only, titled by the PR (repo.md 9) | `github_repository`: `allow_squash_merge`, `allow_merge_commit`, `allow_rebase_merge`, `squash_merge_commit_title = "PR_TITLE"`, `squash_merge_commit_message = "PR_BODY"` | yes |
| Auto-merge, branch deletion, update branch, no wiki (repo.md 10) | `github_repository`: `allow_auto_merge`, `delete_branch_on_merge`, `allow_update_branch`, `has_wiki`, `has_projects` | yes |
| A PR for every change, 0 approvals, stale reviews dismissed, conversations resolved, required checks, no force-push or deletion (security.md 1 to 4) | `github_repository_ruleset` on `~DEFAULT_BRANCH`: `pull_request` (`required_approving_review_count = 0`, `dismiss_stale_reviews_on_push`, `required_review_thread_resolution`, `allowed_merge_methods = ["squash"]`), `required_status_checks` (`required_check` with `context` and `integration_id`, `strict_required_status_checks_policy = false`), `deletion`, `non_fast_forward`. No bypass actors, so admins are held too | yes |
| No Copilot review (security.md 5) | No `copilot_code_review` rule | n/a |
| Dependabot alerts and security updates (security.md 6) | `github_repository_vulnerability_alerts`, `github_repository_dependabot_security_updates` | yes |
| `dependabot.yml` and the auto-merge workflow (security.md 7 to 9) | Files the template seeds; each repo owns them after that (0003) | n/a |
| CodeQL default setup (security.md 13) | `restapi_object`: `PATCH /repos/{owner}/{repo}/code-scanning/default-setup` | yes |
| Secret scanning and push protection (security.md 14) | `github_repository`: `security_and_analysis` | yes |
| Immutable releases (security.md 18) | `restapi_object`: `PUT /repos/{owner}/{repo}/immutable-releases` | yes |
| Immutable image tags (security.md 18) | `docker_hub_repository`: `immutable_tags_settings` | yes |
| Secrets (security.md 19 and 20) | `github_actions_secret`, `github_dependabot_secret`. A value set this way is stored in state, so #12 decides which, if any, Terraform holds | no |
| Private vulnerability reporting (security.md 21) | `restapi_object`: `PUT /repos/{owner}/{repo}/private-vulnerability-reporting` | yes |
| Every action pinned to a full SHA | `github_actions_repository_permissions`: `sha_pinning_required` | yes |
| The issue labels | `github_issue_labels`, one per repo (#8) | no |

The three `restapi_object` rows fill gaps in `integrations/github`, and each one counts toward the 500-resource budget ([DATA.md](DATA.md#hcp-terraform)). Each sets `ignore_server_additions = true`.
