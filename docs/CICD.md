# CI/CD

How a change gets from a PR to main, and later to every consuming repo. #2 adds the checks one PR at a time, and this page grows with each.

## From PR to main

```mermaid
flowchart LR
  branch["branch off main"] --> pr["draft PR"]
  pr --> checks["required checks"]
  checks --> merge["squash merge<br/>PR title becomes the commit"]
  merge --> release["release, when a module path changed"]
```

- Every change reaches main through a PR. The repo allows squash merges only, with the PR title as the commit title and the PR body as the message.
- The PR title is `type(scope): summary`, with a type from `GitVersion.yml`: `feat` releases a minor, a `!` before the colon a major (a change that breaks a caller), and every other type a patch. The `PR Title` job refuses any other title. Records: [0004](architectural-decision-records/0004-one-version-for-every-module.md), [0020](architectural-decision-records/0020-pr-titles-checked-by-a-community-action.md)
- `ci-release.yml` releases yggdrasil through its own release module. On a PR it runs in dry run, and the `Release / Version` job says what the merge will release, or that it releases nothing. On main it tags the merge commit `vX.Y.Z` and publishes an immutable GitHub release with notes from the merged PR titles. A merge that touches no module path gives back a version already tagged, and releases nothing. Record: [0027](architectural-decision-records/0027-release-module.md)

## PR checks

Every job runs in the same pinned container a local `make` run uses. Record: [0018](architectural-decision-records/0018-checks-run-through-make-in-pinned-containers.md)

| Workflow | Job | Runs | Fails on |
|---|---|---|---|
| `checks.yml` | `Lint / actionlint` | The lint module on this repo, from this PR's copy: actionlint, with shellcheck on every `run:`. Record: [0037](architectural-decision-records/0037-lint-module.md) | Any finding in `.github/workflows/` |
| `checks.yml` | `Lint / zizmor` | The lint module: zizmor's pedantic audits, online with the job's read-only token, findings as PR annotations | Any finding: an unpinned action or a version comment that is missing or wrong, `${{ }}` inside `run:`, a checkout that keeps credentials, `pull_request_target`, broad permissions and the rest |
| `checks.yml` | `Lint / semgrep` | The lint module: Semgrep's registry rule `dockerfile-source-not-pinned` | A Dockerfile `FROM` with a tag but no `@sha256:` digest, outside test folders |
| `checks.yml` | `Terraform / fmt` | The terraform module on this repo, from this PR's copy: `terraform fmt -recursive -check`. Record: [0042](architectural-decision-records/0042-terraform-module.md) | A file `terraform fmt` would change |
| `checks.yml` | `Terraform / validate` | The terraform module: `terraform validate` in each folder `checks.yml` lists | Invalid Terraform |
| `checks.yml` | `Terraform / test` | The terraform module: `terraform test` with mock providers, in each listed folder | A failing test |
| `checks.yml` | `Terraform / tflint` | The terraform module: tflint's bundled recommended rules | Any finding, such as an unused variable |
| `checks.yml` | `Terraform / trivy` | The terraform module: Trivy's misconfiguration scan of each listed folder, with `defaults/trivy.yaml` | Any finding |
| `pr-title.yml` | `PR Title` | `amannn/action-semantic-pull-request` on the title, on every edit and push | A title that isn't `type(scope): summary` with a type from `GitVersion.yml`'s patterns. Record: [0020](architectural-decision-records/0020-pr-titles-checked-by-a-community-action.md) |
| `checks.yml` | `Docs` | `make docs`: lychee over every relative link and heading anchor, and a grep for em dashes | A broken link or anchor, or an em dash |
| `ci-docker-build.yml` | `Docker Build Test / Docker Build` | The docker-build module on `tests/docker-build/`. Only on PRs that touch the module, its test or `defaults/trivy.yaml`, so it isn't required | Any failure of the module |
| `ci-release.yml` | `Release / Version` | The release module in dry run: GitVersion on the squash commit this PR will make | GitVersion failing or giving something other than `X.Y.Z` |
| `ci-release.yml` | `Release / Build & Push (zimmertr/yggdrasil-test)` | The same dry run building `tests/docker-build/` for `linux/amd64` and `linux/arm64`, pushing nothing | A build that fails |

Branch protection requires `Lint / actionlint`, `Lint / zizmor`, `Lint / semgrep`, the five `Terraform /` checks, `Docs` and `PR Title` (logged below). A check joins it only after it has reported once, because a required check that never reports blocks every PR. Renaming one of these jobs means updating protection in the same PR. CodeQL's default setup scans the workflows too.

## Settings applied by API

Until #8 imports the repo into Terraform, its settings are API calls that TJ okays first. Each one is logged here, so #8 can check its import against this list. Record: [0014](architectural-decision-records/0014-foundation-by-hand-then-imported.md)

### 2026-11-05, #2 item 0.1

Before: merge commits and rebase merges allowed, the squash commit built from the commit messages, auto-merge off, head branches kept, the update-branch button off, wiki and projects on, Dependabot alerts and security updates off, private vulnerability reporting off, immutable releases off, and `sha_pinning_required` false. Secret scanning and push protection were already on.

| Call | Sets |
|---|---|
| `gh api -X PATCH repos/zimmertr/yggdrasil -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY -F allow_auto_merge=true -F delete_branch_on_merge=true -F allow_update_branch=true -F has_wiki=false -F has_projects=false` | Squash only, with the PR title and body; auto-merge; head branches deleted; update-branch button; wiki and projects off |
| `gh api -X PUT repos/zimmertr/yggdrasil/vulnerability-alerts` | Dependabot alerts |
| `gh api -X PUT repos/zimmertr/yggdrasil/automated-security-fixes` | Dependabot security updates |
| `gh api -X PUT repos/zimmertr/yggdrasil/private-vulnerability-reporting` | Private vulnerability reporting |
| `gh api -X PUT repos/zimmertr/yggdrasil/immutable-releases` | Immutable releases |
| `gh api -X PUT repos/zimmertr/yggdrasil/actions/permissions -F enabled=true -f allowed_actions=all -F sha_pinning_required=true` | Actions must be pinned to a full commit SHA |

Each setting was read back from its endpoint after the call.

### 2026-11-05, #2 item 0.9

TJ okayed both. Before: no branch protection and no code scanning.

| Call | Sets |
|---|---|
| `gh api -X PUT repos/zimmertr/yggdrasil/branches/main/protection --input protection.json` | Required checks `actionlint`, `zizmor`, `Docs` and `PR Title` from GitHub Actions (app 15368), not strict; a PR for every change with 0 approvals and stale reviews dismissed; admins included; conversations resolved; no force-push, no deletion |
| `gh api -X PATCH repos/zimmertr/yggdrasil/code-scanning/default-setup -f state=configured -f query_suite=default -f 'languages[]=actions'` | CodeQL default setup for the workflows |

`protection.json` held exactly those fields; the read-back of `branches/main/protection` matched it.

### 2026-11-06, #6 step 4.4

TJ okayed it. Before: required checks `actionlint`, `zizmor`, `Docs` and `PR Title`.

| Call | Sets |
|---|---|
| `gh api -X PATCH repos/zimmertr/yggdrasil/branches/main/protection/required_status_checks --input checks.json` | Required checks `Lint / actionlint`, `Lint / zizmor`, `Lint / semgrep`, `Docs` and `PR Title` from GitHub Actions (app 15368), not strict |

The call's response listed exactly those five.

## Dependabot

`.github/dependabot.yml` updates the pinned actions (`github-actions`), the providers in each stack's `.terraform.lock.hcl` (`terraform`, every directory under `terraform/`) and the tool images in `compose.yml` (`docker-compose`) weekly, each version waiting seven days after its release. Security updates skip the wait. Titles are `build(deps): ...`, a patch.

`dependabot-auto-merge.yml` arms squash auto-merge on Dependabot's patch and minor updates, with a token minted from `zimmertr-yggdrasil-bot`, and comments on the PR as the bot. Majors, digest-only updates and every Terraform provider update wait for TJ: once a merge applies a stack (#8), a provider bump changes what the next apply does. Record: [0042](architectural-decision-records/0042-terraform-module.md) Record: [0021](architectural-decision-records/0021-dependabot-with-app-auto-merge.md)

## Secrets

| Secret | Kind | Holds | Used by |
|---|---|---|---|
| `YGGDRASIL_BOT_PRIVATE_KEY` | Dependabot | The App's private key, set by TJ | `dependabot-auto-merge.yml` |
| `YGGDRASIL_BOT_PRIVATE_KEY` | Actions | The same key, set by TJ on 2026-11-06 | The Terraform plan and apply, from #8 steps 6.5 and 6.8 |
| `TF_API_TOKEN` | Actions | The HCP Terraform team token for `Yggdrasil-Org`, set by TJ on 2026-11-06 | The Terraform plan and apply, from #8 steps 6.5 and 6.8 |

The key is stored twice because a run Dependabot starts can't read Actions secrets, and other runs can't read Dependabot's. There are no GitHub environments: plan and apply hold the same key, so an environment that locks apply to main would guard nothing the plan doesn't already hold (TJ, 2026-11-06, #8). #13's read-only plan identity is when that changes. The workflow names the App by its public client ID, so `YGGDRASIL_BOT_APP_ID`, which held the App ID, was deleted on 2026-11-05 with TJ's okay. yggdrasil has no `AUTO_MERGE_PAT`: its auto-merge mints an App token instead. Record: [0007](architectural-decision-records/0007-one-bot-identity.md)

Never print, log or paste a secret's value. #12 inventories every secret across TJ's repos and services.
