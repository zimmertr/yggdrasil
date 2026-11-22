# 0062. The riskiest upstreams wait 30 days, and Terraform provider updates merge themselves like every other update

- Status: Accepted. Supersedes 0042 in part (provider updates wait for TJ) and 0056 in part (every update waits seven days)
- Date: 2026-11-21
- Decider: TJ, 2026-11-21, in #133: "No fix adds recurring manual work. Risky upstreams wait 30 days instead of waiting for a review", and "Terraform provider minors and patches merge themselves like every other update". On the Trivy image, asked whether to move its pin from GHCR to Docker Hub so the wait can hold: "Move to Docker Hub".
- Issues and PRs: #133, #131
- Cited in code as: record 0062, in `defaults/renovate.json` and `compose.yml`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "One Renovate preset", and Working in this repo, "Renovate's updates below a major merge themselves"

## Context

#133's audit of every unarchived repo on 2026-11-21 ranked each upstream by what it can reach when it runs and by how thinly it is maintained. A handful hold the App's admin-capable tokens, the HCP and Cloudflare tokens, a deploy token or `packages: write`, and several have one maintainer. Seven days after any of them released, Renovate merged its patch or minor unread. Meanwhile every Terraform provider update in yggdrasil waited for TJ (0042), which is recurring manual work, and https://github.com/zimmertr/yggdrasil/pull/131 sat open on that rule.

## Decision

- `defaults/renovate.json` gives these upstreams `minimumReleaseAge: "30 days"` instead of seven: `dflook/terraform-plan` and `dflook/terraform-apply`, `aquasecurity/trivy-action` and the Trivy images, `peter-evans/create-pull-request`, the five `docker/*` actions, `mikefarah/yq`, `marocchino/sticky-pull-request-comment`, the `dagandersen/argocd-diff-preview` image, `xu-cheng/latex-action`, `softprops/action-gh-release`, and the `Mastercard/restapi` and `integrations/github` providers.
- Below a major they still merge themselves once their wait is over. Nothing in the list waits for TJ.
- yggdrasil's `.github/renovate.json` no longer holds Terraform provider updates, so a provider's minor or patch merges itself and the merge applies it.
- yggdrasil pins Trivy from Docker Hub (`aquasec/trivy`), not GHCR. It is the same image, with the same digest.

## Evidence

- 2026-11-21, #133: `dflook/terraform-plan` and `/terraform-apply` had one author for 99 of their last 100 commits, and `Mastercard/terraform-provider-restapi` one for 82 of its last 90. Both run with the App's write tokens.
- March 2026: attackers force-pushed nearly every `aquasecurity/trivy-action` tag to a credential stealer ([GHSA-69fq-xp46-6x23](https://github.com/aquasecurity/trivy/security/advisories/GHSA-69fq-xp46-6x23)). It was caught in about 12 hours, and SHA pins kept callers safe.
- 2026-11-11, Renovate's docs: only Docker Hub gives an image a publish date, and the preset's `timestamp-optional` lets a GHCR image skip any wait ([`docs/DATA.md`](../DATA.md#github)). So a 30-day rule on `ghcr.io/aquasecurity/trivy` alone would hold nothing.
- 2026-11-21: Docker Hub's `aquasec/trivy:0.76.2` has digest `sha256:8f6bb947...499768fb`, the same index `ghcr.io/aquasecurity/trivy:0.76.2` pinned.
- 2026-11-21: Renovate opened https://github.com/zimmertr/yggdrasil/pull/131 for cloudflare 5.29.0 on 2026-11-19 at 04:52 UTC, seven days and five hours after its GitHub release, so the Terraform registry gives Renovate a publish date and a provider's wait holds.

## Alternatives rejected

- Every update in the list waits for TJ: a review of each one, for ever, which TJ ruled out on 2026-11-21.
- Keep the Trivy pin on GHCR: the wait would name it and never hold it.
- `timestamp-required` on the GHCR image: every Trivy bump would wait for TJ by hand.
- Keep provider updates waiting for TJ (0042): recurring manual work, and the plan comment and the apply's match check stay either way.

## Consequences

- A fix in one of these upstreams also reaches us a month late. Security updates skip `minimumReleaseAge`, so a fix Renovate opens for a vulnerability alert doesn't wait.
- A provider minor or patch applies on merge with no one reading its plan. Its PR still plans, and the apply still refuses a plan that no longer matches the PR's comment ([0045](0045-merges-apply-through-dflook.md)).
- A new upstream that holds a write token joins the list by hand. Nothing finds one.
- A repo that pins Trivy from GHCR gets no wait on it until it moves the pin.
