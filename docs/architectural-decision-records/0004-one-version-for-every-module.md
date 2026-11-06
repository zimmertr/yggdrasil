# 0004. Every module shares one SemVer, released only when a module path changes, and callers pin the commit

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05: "Yes, and then consumes subscribe to these versions and must be bumped… auto-merge non-breaking…"
- Issues and PRs: #1, #3, #4
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "One version for every module"

## Context

Consumers need to know when a module changed and whether the change can break them, and they need a pin that can't move under them.

## Decision

- One SemVer covers every module. A merge to main that changes a module path (`.github/workflows/` reusable workflows, `actions/`, `defaults/`) releases `vX.Y.Z`; any other merge releases nothing.
- The PR title picks the bump. A change that breaks a caller (a removed input, a new required one) carries `!` before the colon, which makes it a major.
- On every PR, CI compares each module's `workflow_call` inputs and outputs with the last release, and fails a breaking change whose title lacks `!`.
- Callers pin the full commit SHA, with `# vX.Y.Z` beside it.

## Evidence

- 2026-11-05: `sha_pinning_required` is on in bluebird, bluebird-helm and Kubernetes-Manifests, so those repos refuse a tag-only `uses:`.
- 2026-11-05: GitVersion 6.8.2 in Mainline mode counts every commit on main, so a settings-only commit needs an ignore rule to bump nothing. #3 settles how.

## Alternatives rejected

- A version per module: more tags, more bump PRs in every consumer, and modules that call each other at mismatched versions.
- Floating major tags such as `@v1`: a tag can move, and the repos with `sha_pinning_required` refuse it.

## Consequences

The breaking-change check holds the version honest (0011). A settings-only PR never wakes the consumers. Every consumer gets a bump PR for every release, which 0005 merges for them.
