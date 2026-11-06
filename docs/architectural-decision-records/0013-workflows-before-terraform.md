# 0013. The modules ship and are proven on hevy-trainer-sync before any Terraform, with one issue per phase

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, at PRD sign-off on 2026-11-05: "The PRD looks good. Signed off." The order is the PRD's "Settled at sign-off" item 3.
- Issues and PRs: #1 to #11
- Cited in code as: none
- Guide: [`docs/PRD.md`](../PRD.md), section 7

## Context

Both halves could start first. The modules change what runs in every repo; the Terraform changes every repo's settings.

## Decision

The work runs in phases, one issue each, chained by blocked-by links under epic #1: the foundation (#2), verification (#3), the modules (#4), hevy-trainer-sync (#5), Bluebird (#6), every other repo (#7), then the GitHub stack (#8), Docker Hub and ArtifactHub (#9), Cloudflare (#10) and ai-config (#11). Each module is proven on hevy-trainer-sync before anything else depends on it.

## Evidence

No dated measurement.

## Alternatives rejected

- Terraform first: the stacks need yggdrasil's CI and the App to exist, and the modules unblock more repos sooner.
- An issue per task: TJ prefers one issue per phase to a flood of small ones.

## Consequences

Settings stay as logged API calls until #8 (0014). hevy-trainer-sync takes every new module first, so it carries the risk of each one before Bluebird does.
