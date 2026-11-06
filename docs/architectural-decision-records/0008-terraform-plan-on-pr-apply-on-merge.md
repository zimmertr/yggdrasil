# 0008. Terraform plans on every PR and applies on merge, with state in HCP Terraform org Yggdrasil-Org

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05: "Plan on PR, apply on merge". On the HCP org: "I couldn't rename the org to Yggdrasil as the name is already taken… I was able to change the name from Kubernetes-Manifests to Yggdrasil-Org… update existing refs"
- Issues and PRs: #8, #10, Kubernetes-Manifests#1888
- Cited in code as: none
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md), Terraform

## Context

Repo and org settings were changed by hand in the UI, with no record and no review. Terraform needs a state backend and a place to run.

## Decision

- Every PR that touches the Terraform posts its `terraform plan`. A merge to main applies it. A weekly plan reports drift.
- State and locks live in HCP Terraform org `Yggdrasil-Org`, in local execution mode: plans and applies run in Actions.
- Plans run only on PRs from yggdrasil's own branches (0010).

## Evidence

- 2026-11-05: the HCP org name `yggdrasil` was taken. Renaming `Kubernetes-Manifests` kept the Cloudflare workspace and its state in place, and Kubernetes-Manifests#1888 pointed that stack's `cloud` block at the new name.

## Alternatives rejected

- A new, empty HCP org: the name TJ wanted was taken, and a rename kept the existing workspace without a state move.
- Applying by hand from a workstation: no review, and the credentials live on one machine.

## Consequences

A setting changes only through a PR once a repo is imported. A change made in the UI shows up in the weekly drift plan. TJ must confirm Kubernetes-Manifests' Cloudflare plan is still clean after the rename (#10 item 8.1).

`Yggdrasil-Org` is on HCP's Free plan, which allows 500 managed resources across every stack ([`docs/DATA.md`](../DATA.md#hcp-terraform)). The estimate on 2026-11-05 was 135 to 200, with each repo's labels held as one resource.

**Leaving HCP stays cheap.** HCP holds only the state and the locks, so nothing here uses a feature only HCP has: no Sentinel or OPA policy sets, no workspace variables, no run tasks, no remote runs, no VCS-driven workspaces. The guardrails are yggdrasil's own CI checks (0011), and the variables and secrets live in GitHub. If the org outgrows the Free plan, or HCP stops fitting, each stack moves like this:

1. Replace its `cloud` block with another backend.
2. Copy the state across, with `terraform init -migrate-state`, or with `terraform state pull` and then `terraform state push`.
3. Swap the HCP team token in CI for the new backend's credentials.
4. Plan, and confirm it shows no changes.

The likeliest target is an S3 bucket in TJ's AWS account. Terraform's S3 backend locks with `use_lockfile`, without a DynamoDB table, and Actions can sign in through GitHub's OIDC with no stored keys. A backend on TJ's home server (MinIO, Postgres or Kubernetes) also works, but GitHub's hosted runners would need a path into the home network, or self-hosted runners.
