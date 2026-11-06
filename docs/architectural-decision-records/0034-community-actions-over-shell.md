# 0034. The modules use a maintained action or input wherever one does what a shell step did

- Status: Accepted
- Date: 2026-11-06
- Decider: TJ, 2026-11-06: "Aren't we supposed to be using existing frameworks instead of rebuilding everything from scratch for this project?", then "Agree on all improvements"
- Issues and PRs: #4
- Cited in code as: decision record 0034, in `.github/workflows/release.yml`, `docker-build.yml`, `image-scan.yml` and `auto-merge.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#module-inputs)

## Context

The modules ported hevy-trainer-sync's and Bluebird's shell steps as they were. Several of them redo what a maintained action already does.

## Decision

- **Trivy's gate** is trivy-action's own `severity: CRITICAL,HIGH` and `exit-code: 1`, in place of a `jq` count. Where a report is needed too (the SARIF, the PR comment), a first run writes it and a second run, reusing its cache, is the gate. `trivy convert` is gone.
- **Sticky comments** are `marocchino/sticky-pull-request-comment`, in place of finding a marker with `gh api`. The auto-merge note uses `only_create`.
- **The release image's tag and labels** come from `docker/metadata-action`, which also gives the build time.
- **The caller's `trivy.yaml` or the default** is one `hashFiles()` expression.
- **The re-push check is gone.** It only covered "Re-run all jobs" after a push, which Docker Hub's immutable tags already refuse. The release scan reads the version tag, which the same immutability fixes to what was pushed, so the digest lookup is gone too.

Kept as shell, each because no action does it: GitVersion in `docker run` (0027), the PR's squash-commit preview, the `jq` that expands images into one scan per platform, the lowercase image name, the latest-release lookup, and `gh pr merge` and `gh release create`, which zizmor recommends.

## Evidence

- 2026-11-06: zizmor 1.32.0's `superfluous-actions` list doesn't name `marocchino/sticky-pull-request-comment`, `docker/metadata-action` or trivy-action. It names `peter-evans/create-or-update-comment` (pedantic).

## Alternatives rejected

- `peter-evans/find-comment` with `create-or-update-comment`: two actions for one job, and zizmor flags the second.

## Consequences

The sticky action writes its own hidden marker, so when hevy-trainer-sync and Bluebird switch over (#5), each open PR gets one new comment beside its old one. The scan comment shows Trivy's table and totals, without the custom count line. Supersedes, in part: 0029's and 0030's marker, 0030's and 0031's `jq` gate, and 0032's re-run check and digest lookup.
