# 0030. The docker-build module builds `linux/amd64` only, takes the smoke test as a script, and is tested on an empty image

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on #4 item 2.9: "LGTM, continue."
- Issues and PRs: #4, #31
- Cited in code as: decision record 0030, in `.github/workflows/docker-build.yml` and `ci-docker-build.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#docker-buildyml)

## Context

hevy-trainer-sync and Bluebird each run a Docker Build job on PRs: hadolint, an amd64 build, a Trivy scan with a sticky comment, a smoke test of their own, and a gate on fixable Critical and High. Bluebird also caches layers and saves the image for later jobs.

## Decision

- Inputs only for what differs between the two: `context`, `build-args`, `smoke-test`, `cache`, `upload-image`. No `platform` input: both build `linux/amd64` on PRs, the cluster's platform.
- The image tag, artifact and comment marker come from the repo name, matching what both repos use today.
- The smoke test is a Bash script input, run with the image's tag in `$IMAGE`.
- `ci-docker-build.yml` tests it on `tests/docker-build/`, a `FROM scratch` image with one label set by a build argument. It runs only on PRs that touch the module, its test or `defaults/trivy.yaml`, so other PRs carry no scan comment, and it isn't a required check.

## Evidence

- 2026-11-05: on #31, the test built the image, uploaded it, scanned it with `defaults/trivy.yaml`, posted the sticky comment and passed its smoke test.

## Alternatives rejected

- A `platform` input: no caller builds anything else on a PR.
- Testing on a real base image: its CVEs would fail yggdrasil's PRs for reasons outside yggdrasil.

## Consequences

Bluebird's fill image keeps its own job, which also runs a database suite. A caller that needs another platform or Dockerfile name adds an input then, as a minor.
