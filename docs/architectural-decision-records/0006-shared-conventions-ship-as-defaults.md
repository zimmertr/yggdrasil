# 0006. The versioning, PR title and scan conventions ship from yggdrasil as defaults a caller can override

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05: "Sure… shared gitversion…"
- Issues and PRs: #1, #4
- Cited in code as: none
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md), Shared defaults

## Context

Every repo copies the same `GitVersion.yml`, the same PR title patterns and the same `trivy.yaml`. A module that reads them needs a copy it can rely on.

## Decision

`defaults/GitVersion.yml` and `defaults/trivy.yaml` live in yggdrasil. A module reads them at its own pinned ref, so a caller gets the version of the convention that matches the module it pinned. A caller can pass its own file instead.

## Evidence

No dated measurement.

## Alternatives rejected

- Each repo keeps its own copy: the copies drift, and the PR title check and GitVersion must agree on the patterns.

## Consequences

Changing a default is a module change and a release, and reaches every consumer that hasn't overridden it. A `./` path inside a reusable workflow resolves in the caller's checkout, so the module must fetch the defaults from yggdrasil at its ref, which it reads from `job.workflow_sha` (0022).
