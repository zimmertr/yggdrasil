# 0059. The pr-preview module builds each PR's preview image on `pull_request`, and Bluebird and hevy-garmin-sync both call it

- Status: Accepted
- Date: 2026-11-13
- Decider: TJ, 2026-11-13, on hevy-garmin-sync#62: option A, "a yggdrasil module for the preview image", and "Yes, use pull_request."
- Issues and PRs: hevy-garmin-sync#62, bluebird#936
- Cited in code as: decision record 0059, in `.github/workflows/pr-preview.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#pr-previewyml)

## Context

Bluebird builds a preview image for each PR, and an Argo CD `ApplicationSet` in Kubernetes-Manifests runs it while the PR carries the `create pr container` label. hevy-garmin-sync needs the same. Bluebird's `pr-preview.yml` runs on `pull_request_target`, which this repo forbids (record 0010). It chose that trigger because Dependabot's `pull_request` runs got a read-only token. Both repos now use Renovate, whose branches are in the repo, so a `pull_request` run gets the write token it asks for.

## Decision

- One module, `pr-preview.yml`. The caller runs it on `pull_request` and passes three inputs: `image`, `url` and `title`.
- The tag is `pr-<N>-<head sha>`, from the PR's head, `linux/amd64` only. A tag already pushed is not rebuilt.
- The build arguments are the release module's: `APP_VERSION` (`pr-<N>`), `APP_COMMIT` and `APP_BUILT_AT`.
- The job runs for same-repo PRs only. The owner's PRs get the label and one comment, kept by `marocchino/sticky-pull-request-comment`; others get only the image.
- `actions/github-script` adds the label, so no shell calls `gh` (record 0034).

## Evidence

No dated measurement. That a Renovate PR's `pull_request` run can push to GHCR is expected from GitHub's token rules and shows on the first Renovate PR in a caller.

## Alternatives rejected

- A copy of Bluebird's workflow in hevy-garmin-sync: two copies of a workflow that writes to GHCR.
- `pull_request_target`, as Bluebird has it: it hands a fork's run the repo's secrets, and record 0010 forbids it.
- Inputs for the context, platform, build arguments or cache: neither caller needs them.

## Consequences

There is no test caller: a push would leave a package in GHCR and a label and comment on yggdrasil's PRs. A caller's PR pinned to the module's branch is the test before release, and its own CI catches a bad bump (record 0025). Bluebird moves to the module in bluebird#936.
