# 0032. The release module builds every image from one JSON list, scans each platform by digest, and releases only after every scan

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on #4 item 2.11: "LGTM, continue"
- Issues and PRs: #4, #33
- Cited in code as: decision record 0032, in `.github/workflows/release.yml` and `ci-release.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#releaseyml)

## Context

hevy-trainer-sync releases one amd64 image. Bluebird releases two images for amd64 and arm64, one with a layer cache and one from `fill/Dockerfile`, and scans each platform by digest before the GitHub release. Both refuse to re-push an image built from another commit.

## Decision

- One `images` input lists every image, with `context`, `file`, `platforms` and `cache` per image. There is no separate list for extra images: the tag and release wait on all of them alike.
- Every image gets the build arguments `APP_VERSION`, `APP_COMMIT` and `APP_BUILT_AT`, the names both repos read, so there is no build-args input.
- The scan job looks the digest up by the version tag, which Docker Hub's immutable tags fix to what the build pushed, and runs once per image and platform without a Docker Hub login.
- The git tag and release are still one `gh release create` (0027), after every scan.
- A dry run builds every platform without pushing, and scans nothing. The PR image module (0030) already scans on PRs.
- hevy-trainer-sync's release guards stay as steps: the revision label check, for both index shapes. The "newer release" guard belongs to the deploy bump (#4 item 2.13).

## Evidence

- 2026-11-05: on #33, the dry run built `tests/docker-build/` for `linux/amd64` and `linux/arm64` with an SBOM and provenance, and pushed nothing.

## Alternatives rejected

- Digests passed from the build job: a matrix job can't output one value per entry.
- A build-args input: the version is only known inside the module.

## Consequences

The push, the scan of a pushed image, and the release after it run first in #5. A caller whose Dockerfile needs other build arguments adds an input then, as a minor.
