# 0060. A chart's checks are helm-unittest suites and an image's a container-structure-test file, never shell

- Status: Accepted
- Date: 2026-11-13
- Decider: TJ, 2026-11-13, on hevy-garmin-sync#67: "Both, and other repos need to align on this solution instead of hand-rolling", and that the rule be written down so future agents follow it.
- Issues and PRs: hevy-garmin-sync#62, hevy-garmin-sync#67
- Cited in code as: record 0060, in `.github/workflows/chart.yml`, `docker-build.yml`, `ci-chart.yml`, `ci-docker-build.yml` and `defaults/renovate.json`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Working in this repo, "Charts and images are tested with standard tools"

## Context

The chart module's `test` input and the docker-build module's `smoke-test` input take Bash. Every caller filled them with hand-written checks: `helm template` piped to `grep` and `test`, and `docker run` scripts with their own pass and fail helpers. hevy-garmin-sync, bluebird, bluebird-helm, trailhead-helm and Mountaineers-Activity-Scraper all did. Each check needed a comment to explain its plumbing, and none named what it asserted.

## Decision

- The chart module runs helm-unittest on every `*_test.yaml` in the chart's `tests/` folder, with no input. It runs helm-unittest's own image, `helmunittest/helm-unittest`, as a `docker://` step pinned by tag and digest. The image runs as uid 1000, which can't write the runner's checkout, and the tool makes a `__snapshot__` folder beside the suites (seen 2026-11-13), so a step first lets every user write the chart's `tests/` folders.
- The docker-build module takes `structure-test`, a container-structure-test file, and runs it against the built image. It runs the tool's own image, `ghcr.io/googlecontainertools/container-structure-test`, as a `docker://` step pinned by tag and digest. The step gets the runner's Docker socket, so it finds the image the module loaded.
- `test` and `smoke-test` stay, deprecated, until their last callers move: bluebird-helm and trailhead-helm for `test`, bluebird and Mountaineers-Activity-Scraper for `smoke-test`. A major release removes them.
- Renovate moves both pins, as it moves every action and image, and nothing is updated by hand (TJ, 2026-11-13: "I will never update anything by hand"). helm-unittest's tags join two versions, as `4.3.0-1.2.1`, so the shared preset, `defaults/renovate.json`, gives it a versioning of its own: the plugin's major is the major, Helm's major is the compatibility, and the rest compare in order. It sits in the preset because a caller's Makefile pins the same image to run the suites locally.
- Renovate has no Makefile manager, so the preset adds one: a regex that reads `NAME := image:tag@sha256:...`. A pin without its digest isn't read, so every Makefile image is pinned the way the modules pin theirs.
- A check neither tool can hold is raised with TJ before any shell is written for it.

## Evidence

- 2026-11-13: container-structure-test v1.22.1's run options are user, privileged, TTY, env file, env vars, capabilities and bind mounts. It can't run a container read-only or with no network, and its commands run to completion, so it can't wait on a long-running process. hevy-garmin-sync dropped its read-only and no-network runs for that reason; its unit tests already prove the preview opens no real client.
- 2026-11-13: helm-unittest v1.2.1 (2026-10-03) ships an image per Helm version, `4.3.0-1.2.1` among them. container-structure-test v1.22.1 ships `ghcr.io/googlecontainertools/container-structure-test:1.22.1`; its gcr.io image stopped at v1.16 in 2023.
- 2026-11-13: Renovate 44.200.0's lookup dry run over a copy pinned to `4.2.0-1.1.2` and `1.21.0` offered `4.3.0-1.2.1` and `1.22.1`, both as minor updates.
- 2026-11-13: Renovate reads a custom regex without multiline mode, so `^` and `$` match only the file's ends and a first pattern found nothing in hevy-garmin-sync's Makefile. With `(?:^|\n)` in their place, the same dry run read all five of its pins and offered trivy `0.68.1` to `0.76.2`, hadolint `v2.12.0` to `v2.15.1` and alpine/helm `4.3.0` to `4.3.1`, pins that had fallen behind by hand.

## Alternatives rejected

- Keeping Bash: every repo writes its own assertions and their plumbing, and a reader has to run them in their head.
- Testcontainers, to run images read-only and offline from the test suite: the test job would need the built image, and the library suits Python repos only.
- Installing helm-unittest as a plugin into the module's Helm: one more shell step, and Helm 4 refuses unsigned plugins without a flag.
- container-structure-test's release binary, checked against a hash kept in the module: Renovate can move a version but not a hash beside it, so every update would be by hand.
- Running the chart job inside helm-unittest's image: the image has no Bash, which the deprecated `test` input needs.

## Consequences

ci-chart.yml and ci-docker-build.yml test both tools on the test chart and image, and keep testing the deprecated inputs until they go. Renovate moves both images. helm-unittest's Helm can run a patch behind the Helm the modules install, until its image for that patch ships.
