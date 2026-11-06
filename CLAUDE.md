# yggdrasil

TJ's GitHub and CI configuration in one public, GPL-3.0 repo. It has two halves: versioned reusable workflows and composite actions that TJ's repos call with a pinned `uses:` and their own inputs, and Terraform that creates and manages TJ's repos and orgs on GitHub, Docker Hub and Cloudflare. The plan is epic #1 and its sub-issues.

## Documentation

The README is TJ's: keep it accurate and in TJ's voice, and never restructure it.

| Doc | Holds |
|---|---|
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to send a change |
| [`SECURITY.md`](SECURITY.md) | Supported versions, private reporting, scope |

## Rules

- **Callers bring their own config.** A module reads everything repo-specific from its `with:` inputs. yggdrasil holds no per-repo pipeline config; the only per-repo data it keeps defines the repos and orgs themselves.
- **One version for every module.** Every merge that changes a module path releases the next SemVer, and a settings-only change releases nothing. Callers pin the commit SHA with `# vX.Y.Z` beside it. A change that breaks a caller carries `!` in its PR title.
- **Every repo is production.** No repo gets a module before another; each takes a release the day it ships, and a bad release is fixed forward.
- **The repo is public.** No tokens, ids or personal data in code, fixtures or logs. Email-Infrastructure and Resume are private: their names and settings may appear here, never their contents.
- **No `pull_request_target`**, and Terraform plans run only on PRs from this repo's own branches.
- **One bot identity.** Automation writes as the App `zimmertr-yggdrasil-bot`, through a short-lived token minted per run. Never read or print its private key, or any secret's value.
- **Settings change only through PRs**, once Terraform manages them (#8). Until then, a settings change is an API call TJ okays first.
- **Skills live in zimmertr/ai-config only**, linked into `~/.claude/skills`. Never copy one into this repo.

## Issues

File issues with the `create-issue` skill from zimmertr/ai-config: the two-sentence summary, the six sections, the hemingway and humanizer passes, one priority, one type, the area labels and the session label. The skill reads the four things below from this section.

- **The reader**: TJ on the board, who knows GitHub and CI but not every module's inputs or every Terraform resource.
- **The gates**: CI passes; the docs page that owns the topic and the decision record change in the same PR; the README changes only to stay accurate.
- **The constraints**: a change that breaks a caller carries `!`; nothing is applied to a repo before its import plans clean; no plan that weakens branch protection or a security setting is applied without TJ's okay; a destroy needs the `destroy-approved` label; never print a secret's value, and never put a private repo's contents in a public output.
- **The areas**: `ci` (yggdrasil's own CI), `modules` (the reusable workflows and composite actions), `terraform` (the stacks for GitHub, Docker Hub and Cloudflare, and `repos/`, `orgs/`, `profiles/`, `schemas/`), `consumers` (switching a repo onto the modules), `security` (credentials, permissions and security settings).

## Working in this repo

- Work in a fresh clone in the session's scratchpad, never in TJ's checkout. Branch from the latest `origin/main`.
- Everything reaches main through a squash-merged PR. Never push to main.
- The PR title is `type(scope): summary`, and it picks the version.
- Actions are pinned to full commit SHAs with the version in a comment. The repo setting `sha_pinning_required` refuses anything else.
