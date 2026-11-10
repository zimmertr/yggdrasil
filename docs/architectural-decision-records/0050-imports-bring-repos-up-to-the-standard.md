# 0050. An import brings a repo up to the module's standard in the same apply, and a repo file may set `has_discussions`

- Status: Accepted. Supersedes 0043 in part: one more key
- Date: 2026-11-10
- Decider: TJ, 2026-11-10, by merging #57 after reading its list of changes. Earlier in #8 step 6.9: "Start with the others", to holding hevy-garmin-sync back.
- Issues and PRs: #8, #57
- Cited in code as: none
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md), a repo's file

## Context

#8 planned each import batch to plan as imports only, with nothing to add or change. The first batch's live settings, read on 2026-11-10, didn't allow that: all five repos use classic branch protection, which the module has no resource for, so its two rulesets are new. ai-config had Dependabot alerts, Dependabot security updates, SHA pinning, immutable releases and CodeQL off, and four repos had Projects or the wiki on.

## Decision

- Each resource GitHub imports by the repo's name is imported: the repo, Dependabot alerts, Dependabot security updates and the Actions permissions. The plan then shows each setting that actually changes.
- The two rulesets and the three `restapi_object` settings are created. A ruleset is added beside the classic protection, so main is never unprotected. Creating a `restapi_object` is a PUT or PATCH that sets what the module wants, whatever it was.
- The apply turns on whatever the standard asks for and the repo lacks. The PR body lists each change for TJ to read before merging.
- After the apply, TJ okays deleting each repo's classic protection.
- `has_discussions`, default `false`, is a repo file key. Bluebird sets it to `true`.
- A repo whose ruleset requires no checks yet waits: the module refuses a public repo with none.

## Evidence

- 2026-11-10, #57's first plan: 20 to import, 25 to add, 9 to change, 0 to destroy. The repo's import showed `has_discussions = true -> null` for Bluebird, because the module didn't set it.
- 2026-11-10: integrations/github v6.13.0's docs import `github_repository_vulnerability_alerts`, `github_repository_dependabot_security_updates` and `github_actions_repository_permissions` by repo name, and `github_repository_ruleset` by `<repo>:<id>`.

## Alternatives rejected

- Change each repo by hand to match first, then import: one more set of API calls per repo, and a settings change TJ can't read in a plan.
- A script, `make export-repo`, to write each file: five short files, written from `gh api` reads.

## Consequences

- An import's plan has adds and changes, so reading it means reading each one, not just counting.
- hevy-garmin-sync is imported after its foundation PR merges and its ruleset requires its checks.
