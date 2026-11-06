# 0012. Each managed repo and org is one YAML file that names a profile, and new repos start from a template

- Status: Accepted, except the profiles, which 0035 replaces with defaults in the stack
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on scope: "Everything updated since Apr 14, 2025… Plus a self-import for yggdrasil too… Also, Personal-Website, Zimmertr, Better Lighter Pack, and Strava heatmap String Builder repos", then "Manage all five + Lakebagger repos". On rollout: "Baseline + what fits".
- Issues and PRs: #7, #8
- Cited in code as: none
- Guide: [`docs/PRD.md`](../PRD.md), sections 3 and 4

## Context

Terraform needs a list of what it manages, and most repos share the same settings. Writing every setting out for twenty repos would hide the few that differ.

## Decision

- One file per repo, `repos/<name>.yml`, and one per org, `orgs/<name>.yml`, read by `terraform/github/`.
- A repo file names a profile, `default` or `archived`, inherits its settings, and overrides only what differs. A new profile is added only when a real difference appears.
- Terraform creates each new repo from a template repo that already holds the caller workflows, `dependabot.yml`, `LICENSE` and `.gitignore`, so its first PR runs the shared CI.
- The scope at the start is the five orgs and twenty repos in [`docs/PRD.md`](../PRD.md#4-core-components). Each is both managed and a consumer of the baseline modules, plus whichever release, image or chart modules fit what it ships.

## Evidence

- 2026-11-05: the two `strava-heatmap-proxy` forks were deleted, not managed. TJ: "I'll delete these forks, theyre not part of the scope."

## Alternatives rejected

- One large file for every repo: every change touches the same file, and a mistake in it reaches every repo.
- Rollout rings or tiers of repos: rejected in 0005.

## Consequences

The schema (0011) validates each file. A new repo is one new file and a merge, under `zimmertr` too: Terraform creates it from the template as the App (0024).
