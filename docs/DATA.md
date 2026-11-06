# Upstream providers

Each service yggdrasil talks to: what it uses there, where that provider's limits and terms are, and every quirk found, dated. This page links to each provider's own limits instead of copying the numbers, because the providers change them. Every link was checked on 2026-11-05.

## GitHub

Uses: Actions (the modules and yggdrasil's own CI), the REST and GraphQL APIs (through Terraform's `integrations/github` provider and `gh`), GitHub Apps, and Dependabot.

- Limits: [REST API rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api), [GitHub App rate limits](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/rate-limits-for-github-apps), [Actions limits](https://docs.github.com/en/actions/reference/limits).
- Terms: [GitHub Terms of Service](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service).
- Provider: [`integrations/github`](https://registry.terraform.io/providers/integrations/github/latest/docs).

Quirks:

- 2026-11-05: Dependabot's metadata reads a calendar-versioned package's year change as a major. tzdata 2025.2 to 2026.6 came through as `version-update:semver-major` (zimmertr/hevy-trainer-sync#36), so it waits for TJ even under patch-and-minor auto-merge.
- 2026-11-05: a merge made with `GITHUB_TOKEN` starts no `on: push` workflow, so a Dependabot merge made that way never releases. A merge made with an App token does start them, and with the Workflows permission it can merge a PR that edits `.github/workflows`.
- 2026-11-05: a caller can pass only stored secrets to a reusable workflow, never a token it minted in an earlier job. A caller job also can't set `environment:`, so a module that needs an environment takes its name as an input. #3 confirms both on a real run.
- 2026-11-05: a fine-grained PAT binds to one owner, and the Bluebird-Forecast org caps its lifetime at 366 days (zimmertr/bluebird#311).
- GitHub has no API to create an org. TJ creates each one in the UI, and Terraform takes over from its import.

## Docker Hub

Uses: the repositories that consumers push images to, and their immutable tags (#9, if #3 shows the provider can set them).

- Limits: [Docker Hub usage and limits](https://docs.docker.com/docker-hub/usage/).
- Terms: [Docker Terms of Service](https://www.docker.com/legal/docker-terms-service/).
- Provider: [`docker/docker`](https://registry.terraform.io/providers/docker/docker/latest/docs).

## ArtifactHub

Uses: the listing of TJ's Helm charts. Documented, not managed by Terraform (#9). Record: [0009](architectural-decision-records/0009-providers-in-scope.md)

- Docs: [ArtifactHub documentation](https://artifacthub.io/docs/).

## Cloudflare

Uses: the stack that moves from Kubernetes-Manifests `terraform/cloudflare` (#10).

- Limits: [Cloudflare API rate limits](https://developers.cloudflare.com/fundamentals/api/reference/limits/).
- Terms: [Cloudflare Website and Online Services Terms](https://www.cloudflare.com/website-terms/).
- Provider: [`cloudflare/cloudflare`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs).

## HCP Terraform

Uses: state and locks for every stack, in org `Yggdrasil-Org`, in local execution mode.

- Docs: [HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs) and [workspace settings](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings).
- Pricing: [HashiCorp pricing](https://www.hashicorp.com/en/pricing).
- Terms: [HashiCorp Website Terms of Service](https://www.hashicorp.com/en/terms-of-service). It covers hashicorp.com itself (last updated March 2018), not the use of HCP Terraform, and the service agreement is not linked here yet.

Both HashiCorp pages answer scripted requests with HTTP 429, so TJ checked them in a browser on 2026-11-05.

Quirks:

- 2026-11-05: `Yggdrasil-Org` is on the Free plan, with a 500 managed-resource limit and no charge (its **Plan & billing** page, read by TJ). The limit covers the whole org, every stack together. HashiCorp's [plans overview](https://developer.hashicorp.com/terraform/cloud-docs/overview): "Free organizations are limited to 500 managed resources."
- 2026-11-05: a managed resource is a `mode = "managed"` resource in a state file HCP Terraform holds, counted from its first plan or apply. Data sources and null resources don't count. Local execution mode still counts, because the state still lives in HCP. HashiCorp's blog post "Continuing HCP Terraform's enhanced free tier experience" defines it, and [Estimate HCP Terraform cost](https://developer.hashicorp.com/terraform/cloud-docs/overview/estimate-cost) shows where to see the org's count. The legacy user-based Free plan ended on 2026-03-31.
- 2026-11-05: the pricing page lists only the paid plans (Essentials, Standard, Premium, each priced per managed resource per month), so it doesn't show the Free plan at all.

- 2026-11-05: the org name `yggdrasil` was already taken. TJ renamed the existing `Kubernetes-Manifests` org to `Yggdrasil-Org` instead, which kept the Cloudflare workspace and its state in place (Kubernetes-Manifests#1888).
