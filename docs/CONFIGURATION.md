# Configuration

Every setting yggdrasil depends on, and where each is set. The repo's own settings are logged in [CICD.md](CICD.md#settings-applied-by-api), and its secrets are listed there too.

## Module inputs

A caller passes all of its configuration as inputs. Record: [0002](architectural-decision-records/0002-callers-bring-their-own-config.md)

### `release.yml`

Works out the next version, then tags the commit and publishes the GitHub release. Record: [0027](architectural-decision-records/0027-release-module.md)

| Input | Default | Does |
|---|---|---|
| `environment` | `''` | The GitHub environment the `Tag and Release` job runs in, for its protection rules. Empty runs it in none |
| `dry-run` | `false` | Works out the version and says it in the job summary, but tags and releases nothing. On a PR, the version is the one the squash merge will get |

- The caller runs it on every push to main, and on PRs with `dry-run: true`. It grants `contents: write` and sets a `concurrency` group so releases run one at a time.
- A `GitVersion.yml` at the caller's root is used. Without one, the module reads `defaults/GitVersion.yml`.
- The caller sees the checks `<caller job> / Version` and `<caller job> / Tag and Release`.

### `pr-title.yml`

Fails a PR whose title isn't `type(scope): summary` with a type from `defaults/GitVersion.yml`'s patterns, so every merge releases the bump its title says. No inputs. Record: [0028](architectural-decision-records/0028-pr-title-module-is-yggdrasils-own-check.md)

- The caller runs it from `pull_request` with `types: [opened, edited, reopened, synchronize]`, so a title edit reruns it, and grants `pull-requests: read`.
- The caller sees the check `<caller job> / PR Title`.

### `auto-merge.yml`

Arms auto-merge on Dependabot's patch and minor version updates and says so in a comment. Majors and digest-only updates wait. No inputs. Record: [0029](architectural-decision-records/0029-auto-merge-module-takes-the-callers-token.md)

| Secret | Does |
|---|---|
| `merge-token` | Required. A token that can merge PRs in the caller's repo, such as its `AUTO_MERGE_PAT`. Store it as a Dependabot secret: a run Dependabot starts can't read Actions secrets |

- The caller runs it on `pull_request` and grants `pull-requests: write`.
- The caller sees `<caller job> / Auto-merge patch and minor updates`, skipped on any PR Dependabot didn't open.

### `docker-build.yml`

On a PR: hadolint, then the `linux/amd64` image built and loaded but not pushed, scanned by Trivy (fixable only), a sticky scan comment, the caller's smoke test, and a failure on any fixable Critical or High. Record: [0030](architectural-decision-records/0030-docker-build-module.md)

| Input | Default | Does |
|---|---|---|
| `context` | `.` | The build context, which holds the `Dockerfile` |
| `build-args` | `''` | Build arguments, one `KEY=value` per line |
| `smoke-test` | `''` | Bash run against the built image, whose tag is in `$IMAGE` (`<repo name>:pr-scan`). Any failing command fails the job |
| `cache` | `false` | Uses the GitHub Actions layer cache |
| `upload-image` | `false` | Saves the image as the artifact `<repo name>-image`, holding `<repo name>-image.tar`, for later jobs to `docker load` |

- The caller runs it on `pull_request` and grants `contents: read` and `pull-requests: write`.
- A `trivy.yaml` at the caller's root is used. Without one, the module reads `defaults/trivy.yaml`.
- The comment's marker is `<!-- <repo name>-image-scan -->`, the one hevy-trainer-sync and Bluebird use today. Dependabot's PRs get the step summary instead, since their token is read-only.
- The caller sees `<caller job> / Docker Build`.

### `image-scan.yml`

Scans each image's `linux/amd64` half at the caller's latest GitHub release, fixable only, sends the findings to the Security tab, and fails only on a fixable Critical or High. Record: [0031](architectural-decision-records/0031-image-scan-module.md)

| Input | Does |
|---|---|
| `images` | Required. A JSON list, one entry per image: `{"image": "zimmertr/bluebird", "category": "trivy-released-image", "remedy": "..."}`. `category` names the Security tab's alert set; keep it the same to keep the history. `remedy` is optional words for the failure message |

- The caller runs it on a `schedule` and `workflow_dispatch`, and grants `contents: read` and `security-events: write`.
- A `trivy.yaml` at the caller's root is used. Without one, the module reads `defaults/trivy.yaml`.
- The caller sees `<caller job> / Scan released image (<image>)` for each image.

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
