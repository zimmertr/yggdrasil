# Configuration

Every setting yggdrasil depends on, and where each is set. Its secrets are listed in [CICD.md](CICD.md#secrets).

## Module inputs

A caller passes all of its configuration as inputs. Record: [0002](architectural-decision-records/0002-callers-bring-their-own-config.md)

### `release.yml`

Works out the next version, builds and pushes the caller's images under it and scans each, then tags the commit and publishes the GitHub release once every scan passes, then opens a PR in each deploy repo that points it at the release. Records: [0027](architectural-decision-records/0027-release-module.md), [0032](architectural-decision-records/0032-release-module-builds-the-images.md), [0033](architectural-decision-records/0033-release-module-bumps-deploys-with-yq.md), [0034](architectural-decision-records/0034-community-actions-over-shell.md), [0052](architectural-decision-records/0052-images-go-to-ghcr-pinned-by-digest.md)

| Input | Default | Does |
|---|---|---|
| `environment` | `''` | The GitHub environment the `Tag and Release` job runs in, for its protection rules. Empty runs it in none |
| `dry-run` | `false` | Works out the version and says it in the job summary, and builds every image without pushing it. Scans, tags and releases nothing. On a PR, the version is the one the squash merge will get |
| `images` | `[]` | A JSON list, one entry per image: `{"image": "zimmertr/bluebird", "context": ".", "file": "fill/Dockerfile", "platforms": "linux/amd64,linux/arm64", "cache": true}`. Each is pushed to `ghcr.io/<image>`, lowercased. Only `image` is required. `context` defaults to the repo root, `file` (a path from the repo root) to the context's `Dockerfile`, `platforms` to `linux/amd64`, `cache` to `false` |
| `deploys` | `[]` | A JSON list, one entry per file to point at the release: `{"repo": "zimmertr/bluebird-helm", "file": "charts/bluebird/Chart.yaml", "set": ".appVersion", "branch": "chore/bump-appversion", "title": "chore(release): bump chart appVersion"}`. `set` is a `yq` path; for a kustomization, `(.images[] \| select(.name == "zimmertr/personal-website")).newTag`, its quotes escaped inside the JSON. The PR title is `title` plus ` to X.Y.Z`. `image` and `digest-set` are optional: with them, the PR also writes the digest of `image` (its full name, such as `ghcr.io/zimmertr/personal-website`) at the release, at the `yq` path `digest-set`, such as `(.images[] \| select(.name == "ghcr.io/zimmertr/personal-website")).digest`. Every other field is required |

| Secret | Does |
|---|---|
| `deploy-token` | A token with contents and pull-requests write on every `deploys` repo, such as the caller's `GH_PAT`. Needed when `deploys` isn't empty |

- The caller runs it on every push to main. It grants `contents: write` and `packages: write`, and sets a `concurrency` group so releases run one at a time. A dry run on PRs is optional: it previews the version, but it also builds every image on every platform.
- A `GitVersion.yml` and a `trivy.yaml` at the caller's root are used. Without them, the module reads its `defaults/`.
- Every image is built with `APP_VERSION`, `APP_COMMIT` and `APP_BUILT_AT` as build arguments and the OCI version, revision and source labels, tagged with the version only, with an SBOM and `provenance: mode=max`.
- `docker/metadata-action` makes the tag and the OCI labels, and lowercases the name. Only a version with no git tag yet is built, so a re-run of a released version builds nothing. Each scan reads the image by its version tag.
- A run for a commit that main has moved past releases nothing: no image, tag, release or deploy PR. The run from main's newest commit releases its change (record 0053).
- GHCR has no immutable tags. A deploy that sets `digest-set` runs the digest it was given, even if someone moves the tag by hand.
- A new package from a public repo starts public, and links to the repo that pushed it.
- A fixable Critical or High on any image or platform stops the tag and release. The image stays pushed; the fix is the next release.
- After the release, `peter-evans/create-pull-request` gives each deploy file one PR on its fixed `branch`, rebuilt off the repo's default branch each release, and squash auto-merge is armed (or a plain squash merge when the checks are already green). A PR still open from an earlier release is moved to the newest.
- A `set` path that matches nothing fails the job.
- To finish an old release that failed, release again from main. "Re-run failed jobs" on it skips the `Version` job, which already passed, so its deploy PR could point the deploy back at an older version.
- `yq` drops a file's blank lines the first time it edits it. Comments stay.
- The caller sees `<caller job> / Version`, `/ Build & Push (<image>)`, `/ Scan Pushed Image (<image>, <platform>)`, `/ Tag and Release` and `/ Deploy Bump (<repo>)`.

### `pr-title.yml`

Fails a PR whose title isn't `type(scope): summary` with a type from `defaults/GitVersion.yml`'s patterns, so every merge releases the bump its title says. No inputs. Record: [0028](architectural-decision-records/0028-pr-title-module-is-yggdrasils-own-check.md)

- The caller runs it from `pull_request` with `types: [opened, edited, reopened, synchronize]`, so a title edit reruns it, and grants `pull-requests: read`.
- The caller sees the check `<caller job> / PR Title`.

### `lint.yml`

actionlint, with shellcheck on every `run:`; zizmor's pedantic audits over the caller's workflows, actions and `dependabot.yml`; and Semgrep's registry rule that a Dockerfile `FROM` with a tag carries a digest too. All three run in the images `compose.yml` pins, read at the commit the caller pinned, so a new tool version reaches a caller with its next pin bump. No inputs. Record: [0037](architectural-decision-records/0037-lint-module.md)

- The caller runs it on `pull_request` and grants `contents: read`.
- zizmor gets the job's read-only token, which turns on its online audits, including a version comment that doesn't match its SHA.
- Semgrep fetches its rule from semgrep.dev on each run, and skips test folders, as its default ignores do. A repo with no Dockerfile passes.
- The rule passes a `FROM` with no tag at all (`FROM python`), as well as `FROM <stage>` and `FROM scratch`. For an image that ships, the `docker-build` module's hadolint refuses the missing tag (DL3006), and the rule then wants the digest. A Dockerfile no `docker-build` call builds has only the rule.
- A finding is fixed, or silenced with its reason: an inline `# zizmor: ignore[<audit>]`, the caller's own `zizmor.yml`, or a `# nosemgrep` comment.
- The caller sees `<caller job> / actionlint`, `<caller job> / zizmor` and `<caller job> / semgrep`.

### `terraform.yml`

`terraform fmt` and tflint over the whole repo, and `terraform validate`, `terraform test` and Trivy's misconfiguration scan in each folder the caller lists. All five run in the images `compose.yml` pins, read at the commit the caller pinned. Record: [0042](architectural-decision-records/0042-terraform-module.md)

| Input | Does |
|---|---|
| `directories` | Required. The Terraform folders to validate, test and scan, separated by spaces: each stack, and each module a stack calls. Trivy run from the repo root never reaches a module a stack calls with data from files, so a module is listed too |

- The caller runs it on `pull_request` and grants `contents: read`.
- `init` runs with `-backend=false` and tests use mock providers, so no job reads state or needs a credential.
- tflint uses its bundled recommended rules, and Trivy `defaults/trivy.yaml`. Neither reads a file of the caller's own yet: no caller has one. Trivy scans Terraform only, and fails on any finding the file doesn't silence.
- The caller sees `<caller job> / fmt`, `/ validate`, `/ test`, `/ tflint` and `/ trivy`.

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
- `marocchino/sticky-pull-request-comment` keeps one scan comment per PR (header `image-scan`). Dependabot's PRs get the step summary instead, since their token is read-only.
- The caller sees `<caller job> / Docker Build`.

### `image-scan.yml`

Scans each image's `linux/amd64` half at the caller's latest GitHub release, fixable only, sends the findings to the Security tab, and fails only on a fixable Critical or High. Record: [0031](architectural-decision-records/0031-image-scan-module.md)

| Input | Does |
|---|---|
| `images` | Required. A JSON list, one entry per image: `{"image": "ghcr.io/zimmertr/bluebird", "category": "trivy-released-image", "remedy": "..."}`, the full reference. `category` names the Security tab's alert set; keep it the same to keep the history. `remedy` is optional words for the failure message |

- The caller runs it on a `schedule` and `workflow_dispatch`, and grants `contents: read` and `security-events: write`.
- A `trivy.yaml` at the caller's root is used. Without one, the module reads `defaults/trivy.yaml`.
- The caller sees `<caller job> / Scan released image (<image>)` for each image.

## An example caller

zimmertr/hevy-garmin-sync calls all six modules, and is the example to copy. Its callers at `3fd4b6b`: [`release.yml`](https://github.com/zimmertr/hevy-garmin-sync/blob/3fd4b6ba23ef0cad4cc3f1e50c1a9e019102a57e/.github/workflows/release.yml) (with the chart job a repo with a Helm chart adds until #74), [`pr.yml`](https://github.com/zimmertr/hevy-garmin-sync/blob/3fd4b6ba23ef0cad4cc3f1e50c1a9e019102a57e/.github/workflows/pr.yml), [`pr-title.yml`](https://github.com/zimmertr/hevy-garmin-sync/blob/3fd4b6ba23ef0cad4cc3f1e50c1a9e019102a57e/.github/workflows/pr-title.yml), [`lint.yml`](https://github.com/zimmertr/hevy-garmin-sync/blob/3fd4b6ba23ef0cad4cc3f1e50c1a9e019102a57e/.github/workflows/lint.yml), [`dependabot-auto-merge.yml`](https://github.com/zimmertr/hevy-garmin-sync/blob/3fd4b6ba23ef0cad4cc3f1e50c1a9e019102a57e/.github/workflows/dependabot-auto-merge.yml) and [`image-scan.yml`](https://github.com/zimmertr/hevy-garmin-sync/blob/3fd4b6ba23ef0cad4cc3f1e50c1a9e019102a57e/.github/workflows/image-scan.yml). It keeps no `GitVersion.yml` or `trivy.yaml`, so the defaults below apply.

- Pin every module to a release's commit SHA, with the version in a comment, so Dependabot can move it. Its `github-actions` entry runs daily with `cooldown: default-days: 3` (record [0023](architectural-decision-records/0023-releases-bake-three-days.md)).
- A caller job's `name` comes first in each check's name: `Docker Build / Docker Build`. Rename the required checks in the same step as the switch.
- Don't give a caller the same `concurrency` group as the module it calls: `pr-title.yml` already sets one.

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

Each stack has its own workspace, created once by hand before its first plan: `dflook/terraform-plan` only selects a workspace, never creates one. The workspace's Terraform version is set to match `compose.yml`'s, because the plan and apply take theirs from it. Record: [0044](architectural-decision-records/0044-pr-plans-run-through-dflook-with-read-only-tokens.md)

| Workspace | Stack | Terraform version |
|---|---|---|
| `github` | `terraform/github` | 1.17.1, created 2026-11-07 with TJ's okay (#8 step 6.5) |
| `cloudflare` | `terraform/cloudflare`, moved from Kubernetes-Manifests with its state (#10) | 1.16.5 |

### An org's file

`orgs/<name>.yml`, one per org, named for its login. It holds only the profile and the billing email; every other org setting is the same on every org, in `terraform/modules/org/`. The defaults live in `terraform/github/orgs.tf`'s `local.org_defaults`. Record: [0051](architectural-decision-records/0051-org-settings-in-terraform.md)

| Key | Default | Does |
|---|---|---|
| `billing_email` | `tj@tjzimmerman.com` | The billing email. Public |
| `name` | none | The display name |
| `description`, `blog`, `email`, `location`, `company`, `twitter_username` | none | The rest of the profile |

The org module sets, on every org: the dependency graph, Dependabot alerts and security updates, secret scanning and push protection on for new repos, so a repo made by hand starts with them before its import; Advanced Security off (GitHub Free); and GitHub's defaults for the rest (members read by default, may create repos and Pages sites, may not fork private repos, no commit sign-off, projects on). A key not in the table fails the plan, and so does a file for an org the stack doesn't manage.

### A repo's file

`repos/<owner>/<name>.yml`, one per repo. The folder is the owner: `zimmertr` or one of the five orgs. A file holds only what differs from these defaults, which live in `terraform/github/main.tf`'s `local.defaults`. Record: [0043](architectural-decision-records/0043-repo-files-hold-no-security-settings.md)

| Key | Default | Does |
|---|---|---|
| `description` | `""` | The repo's description |
| `homepage_url` | none | The website shown beside it |
| `topics` | `[]` | Its topics |
| `visibility` | `public` | `public` or `private`. A private repo on GitHub Free gets no rulesets, secret scanning, CodeQL, private vulnerability reporting or auto-merge |
| `archived` | `false` | Archives the repo. An archived repo is read-only, so only the repo itself stays managed |
| `is_template` | `false` | Marks the repo as a template |
| `has_discussions` | `false` | Turns Discussions on. Bluebird uses them |
| `required_checks` | `[]` | The checks main requires, by name, each pinned to GitHub Actions. A public repo needs at least one, except a `.github` repo |

- A key that isn't in this table fails the plan, and so does a folder for an owner the stack doesn't manage. Terraform would otherwise drop an unknown key without a word.
- No security setting is a key. The repo module turns every one in the table below on for every repo GitHub allows it on. Changing that means changing `terraform/modules/repo/`.
- Labels aren't managed: `create-issue` makes them as it needs them.
- Each owner has its own `github` and `restapi` provider and module block, because a token reaches one owner only. The workflow mints one token per owner from `zimmertr-yggdrasil-bot` and passes them as the sensitive map `github_tokens` (#8 step 6.5).

### What Terraform manages

Each setting `initialize-project` gives a new repo (its `repo.md` and `security.md`), and the resource that holds it. The pins are `integrations/github` 6.13.0 and `Mastercard/restapi` 3.0.0. "Tested" means #3 applied it with the App's token and a second plan found nothing to change ([DATA.md](DATA.md#github)). Record: [0024](architectural-decision-records/0024-terraform-providers-and-new-repos.md)

| Setting | Resource and attributes | Tested |
|---|---|---|
| A new repo, except a `.github` repo | `github_repository` with a `template` block naming `zimmertr/yggdrasil-repo-template`, which holds the PR Title and Lint callers and `dependabot.yml` | yes |
| Squash merge only, titled by the PR (repo.md 9) | `github_repository`: `allow_squash_merge`, `allow_merge_commit`, `allow_rebase_merge`, `squash_merge_commit_title = "PR_TITLE"`, `squash_merge_commit_message = "PR_BODY"` | yes |
| Auto-merge, branch deletion, update branch, no wiki (repo.md 10) | `github_repository`: `allow_auto_merge`, `delete_branch_on_merge`, `allow_update_branch`, `has_wiki`, `has_projects` | yes |
| A PR for every change, 0 approvals, stale reviews dismissed, conversations resolved, required checks, no force-push or deletion (security.md 1 to 4) | `github_repository_ruleset` on `~DEFAULT_BRANCH`: `pull_request` (`required_approving_review_count = 0`, `dismiss_stale_reviews_on_push`, `required_review_thread_resolution`, `allowed_merge_methods = ["squash"]`), `required_status_checks` (`required_check` with `context` and `integration_id`, `strict_required_status_checks_policy = false`), `deletion`, `non_fast_forward`. No bypass actors, so admins are held too | yes |
| No Copilot review (security.md 5) | No `copilot_code_review` rule | n/a |
| Dependabot alerts and security updates (security.md 6) | `github_repository_vulnerability_alerts`, `github_repository_dependabot_security_updates` | yes |
| `dependabot.yml` and the auto-merge workflow (security.md 7 to 9) | Files the template seeds; each repo owns them after that (0003). The template has no auto-merge workflow until #12, because a new repo has no merge token | n/a |
| CodeQL default setup (security.md 13) | `restapi_object`: `PATCH /repos/{owner}/{repo}/code-scanning/default-setup` | yes |
| Secret scanning and push protection (security.md 14) | `github_repository`: `security_and_analysis` | yes |
| Immutable releases (security.md 18) | `restapi_object`: `PUT /repos/{owner}/{repo}/immutable-releases` | yes |
| Immutable image tags (security.md 18) | None: GHCR has none, so deploys pin the digest instead (record 0052) | n/a |
| Secrets (security.md 19 and 20) | `github_actions_secret`, `github_dependabot_secret`. A value set this way is stored in state, so #12 decides which, if any, Terraform holds | no |
| Private vulnerability reporting (security.md 21) | `restapi_object`: `PUT /repos/{owner}/{repo}/private-vulnerability-reporting` | yes |
| Every action pinned to a full SHA | `github_actions_repository_permissions`: `sha_pinning_required` | yes |
| The shared issue templates and `SECURITY.md`, and a README, in each owner's `.github` repo only | `github_repository_file`, one per file in `community-health-files/`, committed to the default branch by the bot | yes, 2026-11-07 |

A repo named `.github` differs in three ways, with no key in its file (record 0046): its default-branch ruleset lets the bot (App ID 5636772) bypass it, so the bot can commit the shared files, while everyone else still needs a PR; it requires no checks, since it has no CI; and it gets no CodeQL, since it holds no code.

The three `restapi_object` rows fill gaps in `integrations/github`, and each one counts toward the 500-resource budget ([DATA.md](DATA.md#hcp-terraform)). Each sets `ignore_server_additions = true`.
