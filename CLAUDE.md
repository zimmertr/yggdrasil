# yggdrasil

TJ's GitHub and CI configuration in one public, GPL-3.0 repo. It has two halves: versioned reusable workflows and composite actions that TJ's repos call with a pinned `uses:` and their own inputs, and Terraform that creates and manages TJ's repos and orgs on GitHub, Docker Hub and Cloudflare. The plan is epic #1 and its sub-issues.

## Documentation

Prose lives in `docs/`. A change that makes any of it untrue updates it in the same PR, and every decision gets a record in the same PR, linked from the rule that states it. The README is TJ's: keep it accurate and in TJ's voice, and never restructure it. Record: [0017](docs/architectural-decision-records/0017-docs-and-records.md)

| Doc | Holds |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | The signed-off design: requirements, features, scope, phases |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | The layout, how a repo uses a module, how a setting changes, and which issue builds each part |
| [`docs/CICD.md`](docs/CICD.md) | From PR to main, the settings applied by API, and every secret |
| [`docs/CONFIGURATION.md`](docs/CONFIGURATION.md) | Module inputs, the shared defaults, the App's permissions and installations, Terraform's backend |
| [`docs/DATA.md`](docs/DATA.md) | Each provider's limits and terms, and every quirk found, dated |
| [`docs/USAGE.md`](docs/USAGE.md) | What TJ sees, and what to do when it breaks |
| [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) | The CI-first loop, the `make` targets, how to write tests |
| [`docs/architectural-decision-records/`](docs/architectural-decision-records/README.md) | One record per decision. The README is the index and says how to write one |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to send a change |
| [`SECURITY.md`](SECURITY.md) | Supported versions, private reporting, scope |

## Rules

- **One repo for both halves**, public and GPL-3.0. Record: [0001](docs/architectural-decision-records/0001-one-public-gpl-3-monorepo.md)
- **Callers bring their own config.** A module reads everything repo-specific from its `with:` inputs. yggdrasil holds no per-repo pipeline config; the only per-repo data it keeps defines the repos and orgs themselves. Record: [0002](docs/architectural-decision-records/0002-callers-bring-their-own-config.md) Dependency config stays in each repo, and only the auto-merge is shared. Record: [0003](docs/architectural-decision-records/0003-dependency-config-stays-per-repo.md)
- **One version for every module.** Every merge that changes a module path releases the next SemVer, and a settings-only change releases nothing. Callers pin the commit SHA with `# vX.Y.Z` beside it. A change that breaks a caller carries `!` in its PR title. Record: [0004](docs/architectural-decision-records/0004-one-version-for-every-module.md)
- **Every repo is production.** No repo gets a module before another; each takes a release once it is three days old, patch and minor bumps merge themselves, and a bad release is fixed forward. Record: [0023](docs/architectural-decision-records/0023-releases-bake-three-days.md)
- **Shared conventions are defaults.** `GitVersion.yml`, the PR title patterns and `trivy.yaml` ship from `defaults/`, read at the module's pinned ref, and a caller can pass its own. Record: [0006](docs/architectural-decision-records/0006-shared-conventions-ship-as-defaults.md) A module reads that ref from `job.workflow_sha`. Record: [0022](docs/architectural-decision-records/0022-modules-load-their-own-files-from-the-job-context.md)
- **One bot identity.** Automation writes as the App `zimmertr-yggdrasil-bot`, through a short-lived token minted per run. Never read or print its private key, or any secret's value. Record: [0007](docs/architectural-decision-records/0007-one-bot-identity.md)
- **Terraform plans on every PR and applies on merge**, with state in HCP Terraform org `Yggdrasil-Org`, for GitHub, Docker Hub and Cloudflare. ArtifactHub is documented, not managed. Records: [0008](docs/architectural-decision-records/0008-terraform-plan-on-pr-apply-on-merge.md), [0009](docs/architectural-decision-records/0009-providers-in-scope.md)
- **The repo is public.** No tokens, ids or personal data in code, fixtures or logs. Terraform manages settings, never a repo's files, so Email-Infrastructure's and Resume's names and settings may appear here, never their contents. Record: [0010](docs/architectural-decision-records/0010-safe-in-public.md)
- **No `pull_request_target`**, and Terraform plans run only on PRs from this repo's own branches, with the App's full token for now (#13). Records: [0010](docs/architectural-decision-records/0010-safe-in-public.md), [0016](docs/architectural-decision-records/0016-pr-plans-keep-the-admin-token-for-now.md)
- **Guardrails are CI checks**: the release `dry-run`, import before apply, the schema that refuses weaker settings, and the `destroy-approved` gate. Record: [0011](docs/architectural-decision-records/0011-guardrails-as-code.md) There is no breaking-change check: a caller's own CI fails a bump that breaks it. Record: [0025](docs/architectural-decision-records/0025-no-breaking-change-check.md)
- **One YAML file per repo and per org**, each naming a profile (`default` or `archived`); new repos start from the template. Record: [0012](docs/architectural-decision-records/0012-one-file-per-repo-and-org.md)
- **Workflows before Terraform**, one issue per phase under #1. Record: [0013](docs/architectural-decision-records/0013-workflows-before-terraform.md)
- **Settings change only through PRs**, once Terraform manages them (#8). Until then, a settings change is an API call TJ okays first, logged in [`docs/CICD.md`](docs/CICD.md#settings-applied-by-api). Record: [0014](docs/architectural-decision-records/0014-foundation-by-hand-then-imported.md)
- **Skills live in zimmertr/ai-config only**, linked into `~/.claude/skills`. Never copy one into this repo. Record: [0015](docs/architectural-decision-records/0015-skills-live-in-ai-config.md)

## Issues

File issues with the `create-issue` skill from zimmertr/ai-config: the two-sentence summary, the six sections, the hemingway and humanizer passes, one priority, one type, the area labels and the session label. The skill reads the four things below from this section.

- **The reader**: TJ on the board, who knows GitHub and CI but not every module's inputs or every Terraform resource.
- **The gates**: CI passes; the docs page that owns the topic and the decision record change in the same PR; the README changes only to stay accurate.
- **The constraints**: a change that breaks a caller carries `!`; nothing is applied to a repo before its import plans clean; no plan that weakens branch protection or a security setting is applied without TJ's okay; a destroy needs the `destroy-approved` label; never print a secret's value, and never put a private repo's contents in a public output.
- **The areas**: `ci` (yggdrasil's own CI), `modules` (the reusable workflows and composite actions), `terraform` (the stacks for GitHub, Docker Hub and Cloudflare, and `repos/`, `orgs/`, `profiles/`, `schemas/`), `consumers` (switching a repo onto the modules), `security` (credentials, permissions and security settings).

## Working in this repo

- Work in a fresh clone in the session's scratchpad, never in TJ's checkout. Branch from the latest `origin/main`.
- Everything reaches main through a squash-merged PR. Never push to main.
- The PR title is `type(scope): summary` with a type from `GitVersion.yml` (`feat` is a minor, `!` a major, the rest patches), and it picks the version. The `PR Title` job (action-semantic-pull-request) refuses anything else, and its `types` list changes with `GitVersion.yml` in the same PR. Record: [0020](docs/architectural-decision-records/0020-pr-titles-checked-by-a-community-action.md)
- Actions are pinned to full commit SHAs with the version in a comment. The repo setting `sha_pinning_required` refuses a tag, and zizmor refuses a SHA whose comment is missing or wrong.
- **Use a maintained tool before writing a check.** zizmor (pedantic) holds the workflows, lychee the doc links, and a grep the em dashes. Write custom code only for a gap no tool covers. Record: [0019](docs/architectural-decision-records/0019-community-tools-hold-workflows-and-docs.md)
- **CI runs the checks.** Every check is a `make` target in a pinned container from `compose.yml`, run the same way in CI; commit early and read the jobs. Record: [0018](docs/architectural-decision-records/0018-checks-run-through-make-in-pinned-containers.md)
- **Dependabot's patch and minor updates merge themselves**, armed by a token from `zimmertr-yggdrasil-bot`; majors wait for TJ. Record: [0021](docs/architectural-decision-records/0021-dependabot-with-app-auto-merge.md)
- **Branch protection** requires the checks below, admins included, with conversations resolved; renaming a job means updating protection in the same PR.
- Checks today: `actionlint`, `zizmor`, `Docs`, `PR Title` ([`docs/CICD.md`](docs/CICD.md#pr-checks)).
