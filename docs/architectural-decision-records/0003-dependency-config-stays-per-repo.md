# 0003. Dependency config stays in each repo, and only the auto-merge is shared

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on sharing Dependabot configs centrally: "Sounds like bending Dependabot… Which do you think is best? I want to avoid over engineering here and KISS."
- Issues and PRs: #1, #4, #7
- Cited in code as: none
- Guide: [`docs/PRD.md`](../PRD.md), requirement 8

## Context

TJ asked whether `dependabot.yml` could be shared too. Dependabot reads its config only from the repo it runs in, so sharing it would mean generating or syncing a file into every repo.

## Decision

Each repo keeps its own `dependabot.yml` or `renovate.json`. yggdrasil shares only the auto-merge logic, as a module. Kubernetes-Manifests keeps Renovate.

## Evidence

No dated measurement.

## Alternatives rejected

- A central `dependabot.yml` synced into every repo: it works against how Dependabot reads its config, and the sync is one more thing to break.

## Consequences

The template repo (0012) seeds a new repo's `dependabot.yml`, and after that each repo owns it. A rule every repo should follow, such as a cooldown, is set repo by repo.
