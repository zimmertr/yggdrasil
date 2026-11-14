# 0060. A chart's checks are helm-unittest suites and an image's a container-structure-test file, never shell

- Status: Accepted
- Date: 2026-11-13
- Decider: TJ, 2026-11-13, on hevy-garmin-sync#67: "Both, and other repos need to align on this solution instead of hand-rolling", and that the rule be written down so future agents follow it.
- Issues and PRs: hevy-garmin-sync#62, hevy-garmin-sync#67
- Cited in code as: record 0060, in `.github/workflows/chart.yml`, `docker-build.yml`, `ci-chart.yml` and `ci-docker-build.yml`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Working in this repo, "Charts and images are tested with standard tools"

## Context

The chart module's `test` input and the docker-build module's `smoke-test` input take Bash. Every caller filled them with hand-written checks: `helm template` piped to `grep` and `test`, and `docker run` scripts with their own pass and fail helpers. hevy-garmin-sync, bluebird, bluebird-helm, trailhead-helm and Mountaineers-Activity-Scraper all did. Each check needed a comment to explain its plumbing, and none named what it asserted.

## Decision

- The chart module runs helm-unittest on every `*_test.yaml` in the chart's `tests/` folder, with no input. It runs helm-unittest's own image, `helmunittest/helm-unittest`, pinned by tag and digest at the Helm minor the module installs, as a `docker://` step.
- The docker-build module takes `structure-test`, a container-structure-test file, and runs it against the built image. No maintained action installs the tool and its gcr.io image stopped at v1.16 in 2023, so the module downloads the release binary and checks it against the SHA-256 its release published.
- `test` and `smoke-test` stay, deprecated, until their last callers move: bluebird-helm and trailhead-helm for `test`, bluebird and Mountaineers-Activity-Scraper for `smoke-test`. A major release removes them.
- A check neither tool can hold is raised with TJ before any shell is written for it.

## Evidence

- 2026-11-13: container-structure-test v1.22.1's run options are user, privileged, TTY, env file, env vars, capabilities and bind mounts. It can't run a container read-only or with no network, and its commands run to completion, so it can't wait on a long-running process. hevy-garmin-sync dropped its read-only and no-network runs for that reason; its unit tests already prove the preview opens no real client.
- 2026-11-13: helm-unittest v1.2.1 (2026-10-03) ships an image per Helm version, `4.3.0-1.2.1` among them.

## Alternatives rejected

- Keeping Bash: every repo writes its own assertions and their plumbing, and a reader has to run them in their head.
- Testcontainers, to run images read-only and offline from the test suite: the test job would need the built image, and the library suits Python repos only.
- Installing helm-unittest as a plugin into the module's Helm: one more shell step, and Helm 4 refuses unsigned plugins without a flag.

## Consequences

ci-chart.yml and ci-docker-build.yml test both tools on the test chart and image, and keep testing the deprecated inputs until they go. Renovate moves the helm-unittest image. The container-structure-test version and hash change by hand, together.
