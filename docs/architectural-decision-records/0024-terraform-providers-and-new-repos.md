# 0024. Terraform creates each new repo from the template, protects it with a ruleset, and fills the GitHub provider's gaps with Mastercard/restapi

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on #24, the recommendation from #3's tests: "24 can go when you are ready." On rulesets: "I want to use industry best practices for this repo."
- Issues and PRs: #3, #8, #9
- Cited in code as: none yet; #8's stack cites it
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#what-terraform-manages)

## Context

#8 manages every repo's settings with Terraform, as the App. #3 had to find out how a repo under `zimmertr` gets created, which settings `integrations/github` can hold, and how branches are protected.

## Decision

- **A new repo comes from the template.** `github_repository` with a `template` block creates it, under `zimmertr` or an org, with the App's installation token. The template already holds the caller workflows and `dependabot.yml` (0012).
- **Branches are protected by a `github_repository_ruleset`**, not `github_branch_protection`, so each required check names the app that must report it. yggdrasil's own classic protection moves to a ruleset when #8 imports it.
- **`Mastercard/restapi` fills the three gaps** in `integrations/github` 6.13.0: private vulnerability reporting, immutable releases and CodeQL default setup. Each `restapi_object` sets `ignore_server_additions = true`. When the GitHub provider adds a resource for one, it replaces the `restapi_object` in the same PR.
- **A file Terraform writes to a repo goes in before the ruleset**, or the template seeds it. The App is not a ruleset bypass actor.

## Evidence

- 2026-11-05 (#3): an installation token's `POST /user/repos` got 403 twice. A `github_repository` with a `template` block created `yggdrasil-probe-created-api` with the same token, and a second plan found nothing to change.
- 2026-11-05 (#3): every row of [CONFIGURATION.md](../CONFIGURATION.md#what-terraform-manages) marked tested applied to an imported repo, read back as set, and planned clean the second time.
- 2026-11-05 (#3): `github_repository_file` failed with "409 Repository rule violations found" while the ruleset already existed.
- 2026-11-05: `Mastercard/restapi` v3.0.0 was released 2026-02-27, its repo was last pushed 2026-09-23, and the registry counts about 40 million downloads.

## Alternatives rejected

- `gh repo create` by hand, then an import: a step outside Terraform for every new repo, and `gh` runs as TJ, not the App.
- `github_branch_protection`: it can't say which app must report a required check, so any app could report one with that name.
- A script of `gh api` calls for the three gaps: custom code beside Terraform, with no plan to show drift.
- Leaving the three gaps unmanaged until the provider covers them: one was closed as stale in 2024, and the other two are still open.

## Consequences

Each repo spends three of the 500 managed resources on the gaps. Terraform won't see immutable releases turned off by hand, because that endpoint takes no body for `restapi` to compare. Making the App a ruleset bypass actor would let it commit to main later, and would also let it skip the checks, so that stays a separate decision.
