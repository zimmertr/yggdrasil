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
