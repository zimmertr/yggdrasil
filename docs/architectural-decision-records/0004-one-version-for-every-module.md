# 0004. Every module shares one SemVer, released only when a module path changes, and callers pin the commit

- Status: Accepted, except the breaking-change check, which 0025 drops
- Date: 2026-11-05
- Decider: TJ, 2026-11-05: "Yes, and then consumes subscribe to these versions and must be bumped… auto-merge non-breaking…"
- Issues and PRs: #1, #3, #4
- Cited in code as: decision record 0004, in `GitVersion.yml`
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
- 2026-11-05: GitVersion 6.8.2 in Mainline mode counts every commit on main, so a settings-only commit needs an ignore rule to bump nothing.
- 2026-11-05 (#3): GitVersion 6.8.2 ran in its container on made-up histories that started at `v0.1.0`, with `GitVersion.yml`'s `ignore.paths` rule, which matches every path outside the module paths. A module `fix:`, then a `feat!:` that touched only `terraform/`, then a `docs:` that touched only `README.md`, gave 0.1.1; without the rule, 1.0.1. A `feat!:` that touched a module and `terraform/` together still gave a major. With the module fix already tagged `v0.1.1`, the two later commits gave 0.1.1 again, with `Sha` pointing at the tagged commit rather than HEAD.
- 2026-11-05 (#3): every commit in a made-up history needs its own timestamp. With all of them in the same second, GitVersion applied one patch for the whole run of commits, `feat!:` and all.

## Alternatives rejected

- A version per module: more tags, more bump PRs in every consumer, and modules that call each other at mismatched versions.
- Floating major tags such as `@v1`: a tag can move, and the repos with `sha_pinning_required` refuse it.

## Consequences

The breaking-change check holds the version honest (0011). A settings-only PR never wakes the consumers, but a change to yggdrasil's own CI does: it lives in `.github/workflows/` beside the modules, so it releases a patch. Every consumer gets a bump PR for every release, which 0023 merges for them.
