# 0009. Terraform manages GitHub, Docker Hub and Cloudflare, and ArtifactHub is documented, not managed

- Status: Superseded in part by 0040
- Date: 2026-11-05
- Decider: TJ, 2026-11-05: "Github, Dockerhub, ArtifactHub, Cloudflare". On Cloudflare: "Move the stack here". On ArtifactHub, agreeing to drop it from Terraform: "codify how to manage it for future helm charts".
- Issues and PRs: #8, #9, #10
- Cited in code as: none
- Guide: [`docs/DATA.md`](../DATA.md)

## Context

TJ's settings live on four services. Each needs either a Terraform provider that can manage it, or a written process.

## Decision

- **GitHub**: managed, through `integrations/github`, with `Mastercard/restapi` for the settings it lacks (#8, 0024).
- **Docker Hub**: managed, through Docker's provider, which sets immutable tags (#9).
- **Cloudflare**: the existing stack moves whole from Kubernetes-Manifests `terraform/cloudflare`, with its state, and must plan clean before anything changes (#10).
- **ArtifactHub**: documented, not managed. yggdrasil writes down the standard steps for listing a Helm chart: registering it, `artifacthub-repo.yml` for the verified publisher, and editing a record in place instead of re-registering it.

## Evidence

- 2026-11-05 (#3): `docker/docker` 0.7.0 created a Docker Hub repo with immutable tags `.*`, planned clean the second time, and Docker Hub then refused a second push of the same tag. [`docs/DATA.md`](../DATA.md#docker-hub)

## Alternatives rejected

- Managing ArtifactHub with Terraform: few charts, rare changes, and no provider was settled on; written steps cover it.
- Leaving the Cloudflare stack in Kubernetes-Manifests: two places would manage TJ's settings.

## Consequences

Each provider's limits and terms are linked and dated in [`docs/DATA.md`](../DATA.md). A new chart follows the written ArtifactHub steps by hand.
