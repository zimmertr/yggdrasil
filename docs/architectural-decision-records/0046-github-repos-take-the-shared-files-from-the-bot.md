# 0046. Each owner's `.github` repo gets the shared files from the repo module, committed by the bot past the PR rule

- Status: Accepted
- Date: 2026-11-07
- Decider: TJ, 2026-11-07, in #8 step 6.17: on how the bot gets past the `.github` repos' PR rule, "exception for the bot"; on CodeQL there, "Sure", to leaving it off.
- Issues and PRs: #8, #51
- Cited in code as: decision record 0046, in `terraform/modules/repo/main.tf`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md), what Terraform manages

## Context

[0041](0041-one-source-for-community-health-files.md) keeps the issue templates and `SECURITY.md` once, in `community-health-files/`, and has Terraform copy them into the public `.github` repo of the zimmertr account and each org. TJ made the six repos empty by hand on 2026-11-06, since an App can't create a repo under a user account. Every public repo the module manages requires PRs on main, and the bot can't commit through that rule (a 409, `docs/DATA.md`, 2026-11-05).

## Decision

- The six `.github` repos each get a file under `repos/<owner>/` and an import block in `terraform/github/imports.tf`, like any other repo.
- The repo module spots a repo named `.github` by its name, with no key in the repo file. For those repos only:
  - one `github_repository_file` per file in `community-health-files/`: the templates at `.github/ISSUE_TEMPLATE/`, `SECURITY.md` at the root, committed to the default branch by the bot;
  - the default-branch ruleset has one bypass actor, the bot (App ID 5636772), so its commits get through while everyone else still needs a PR;
  - no required checks, since the repo has no CI;
  - no CodeQL, since there's no code to scan.
- No other repo gets a file resource. A test checks both sides.
- The tokens add Contents write, on a PR too since [0047](0047-pr-plans-use-the-applys-write-tokens.md).

## Evidence

- 2026-11-07, on #51: the plan, with read-only tokens, read all six repos and showed 6 to import, 66 to add (11 per repo, 4 of them files), 6 to change and 0 to destroy. The changes set each repo's merge and wiki settings to the standard and turn secret scanning on.
- 2026-11-07, on #51: a mock provider can't import, so the stack's test stands in for the imported repo with `override_resource`.
- 2026-11-07, the first apply (hand-started, per 0048): the six imports, their settings and both rulesets applied, and all 24 file writes failed with `404 Not Found`, because `branch = "main"` made the provider check for a branch an empty repo doesn't have. The module now leaves `branch` out (`docs/DATA.md`).

## Alternatives rejected

- No PR rule on the `.github` repos: anyone with write access could change the templates on main, and the next apply would overwrite them.
- A `community` key in repo files: one more key to check, for what the repo's name already says.
- CodeQL on the `.github` repos: nothing to scan, and GitHub may refuse it on a repo with no code, which would fail the apply halfway.

## Consequences

- A change to `community-health-files/` shows in the plan as an update to six files, and lands as one bot commit per file per repo.
- Each `.github` repo holds 11 managed resources, 66 in all toward the 500 the HCP Free plan allows.
- A repo's own `.github/ISSUE_TEMPLATE/` or `SECURITY.md` hides the shared ones, so after the apply one PR in each repo that has a copy deletes it.
