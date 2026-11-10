# 0051. Terraform manages each org's settings, the same on every org, with security on for its new repos and no drift report

- Status: Accepted
- Date: 2026-11-10
- Decider: TJ, 2026-11-10, in #8 steps 6.13 and 6.14: "I want to manage and import these args with/into TF"; "Yes" to moving every org's billing email to tj@tjzimmerman.com, public, and "Yes" to the settings standard below; "Drop 6.14. I will never review these drift reports."
- Issues and PRs: #8
- Cited in code as: decision record 0051, in `terraform/github/orgs.tf`, `terraform/modules/org/` and `.github/workflows/terraform-github.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md), an org's file

## Context

The five orgs (Bluebird-Forecast, Fellfield-Game, GPX-Search, TJs-Kubernetes-Service and Lakebagger) had GitHub's default settings, set by hand. Each has one member, TJ, and one repo, its `.github`. Repos will move into them, starting with Bluebird's rebrand (zimmertr/bluebird#311).

## Decision

- `terraform/modules/org/` holds one `github_organization_settings` per org. `orgs/<name>.yml` holds only the profile and the billing email; the stack refuses any other key, and any file for an org it doesn't manage.
- On every org: the dependency graph, Dependabot alerts and security updates, secret scanning and push protection are on for new repos, so a repo made by hand starts with them before its import. Advanced Security is off (GitHub Free). The rest stays at GitHub's defaults, set so a hand change shows in the plan.
- The billing email defaults to tj@tjzimmerman.com, in the open: it isn't a secret.
- Each org's token also gets Organization administration write.
- No weekly drift report (#8 step 6.14): the next apply puts back any setting changed by hand.

## Evidence

- 2026-11-10, `GET /orgs/<name>` for all five: the same settings everywhere, every "for new repositories" security default off, one member and no outside collaborators.
- 2026-11-10: `integrations/github` v6.13.0's `github_organization_settings` requires `billing_email`, and imports by org id.

## Alternatives rejected

- Leave org settings unmanaged: a repo made by hand in an org would start without secret scanning or Dependabot until its import.
- Stop members creating repos, default member permission none, and commit sign-off: none of them limits an owner, and TJ is the only member.
- The billing email in a secret: one more secret for a value TJ is fine to publish.
- A weekly drift plan: TJ won't read it, and a hand change is undone by the next apply.

## Consequences

- A setting changed by hand stays until the next merge that touches the stack, and shows in that PR's plan.
- A new org takes one PR across the stack's files (`docs/USAGE.md`).
- A plan prints the billing email, old and new. #63's plan, on 2026-11-10, showed each org's billing email before the change, so the bot's token can read it.
