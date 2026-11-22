# 0066. A release attests every image and chart it pushes, and docker-build takes the release's images list

- Status: Accepted. Superseded in part by 0067
- Date: 2026-11-21
- Decider: TJ, 2026-11-21, in #133: "Breaking changes ship together. Step 8's three changes go in one PR and one major release", and "`docker-build` takes the release module's `images` list."
- Issues and PRs: #133
- Cited in code as: decision record 0066, in `.github/workflows/release.yml` and `.github/workflows/docker-build.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#releaseyml)

## Context

#133's audit found that releases carried BuildKit's provenance and SBOM, but nothing was signed, so nobody could prove an image in GHCR came from a release run. It also found that the `docker-build` module built only `<context>/Dockerfile`, so trailhead rebuilt the module by hand for its four images, and Bluebird repeated its Trivy gate for a second image. Both changes break callers, so they ship together in one major.

## Decision

- The release module's `Build & Push` and `Push Chart` jobs attest each image index and chart they push with `actions/attest`, as SLSA build provenance. The attestation is kept by GitHub and pushed to GHCR beside the artifact. A dry run attests nothing.
- Those jobs ask for `attestations: write` and `id-token: write`, so every caller grants both. `create-storage-record` is off, so callers don't also grant `artifact-metadata: write`.
- A chart's subject is the manifest digest `helm push` prints.
- `docker-build` takes `images`, the release module's list, and builds each entry as a matrix job, with `structure-test` as a field of an entry. The `context`, `cache` and `structure-test` inputs are gone. Each image's artifact, local tag and scan comment are named after its last path segment, so a repo whose one image shares its name keeps the artifact name it had.
- The `lighthouse` module takes an `image` input, naming which of those artifacts to audit.
- `docs/CONFIGURATION.md` shows how to check an image or chart with `gh attestation verify`.

## Evidence

- 2026-11-21, `actions/attest-build-provenance`'s README: "As of version 4, `actions/attest-build-provenance` is simply a wrapper on top of `actions/attest`", and new implementations should use `actions/attest`. #133 named the wrapper.
- 2026-11-21, `actions/attest`'s `action.yml` (v4.2.2): `create-storage-record` defaults to true and needs `artifact-metadata: write`. `push-to-registry` needs a single OCI reference with a SHA-256 digest.
- 2026-11-21: yggdrasil's own `release.yml` already pushed charts with official Helm from `azure/setup-helm`. `alpine/helm` was left only in hevy-garmin-sync's `Makefile`, for local runs, so #133 step 8's third change had nothing left to do here.
- 2026-11-21, `ci-docker-build.yml` on this PR: two entries, one with `file`, built and scanned as two checks.

## Alternatives rejected

- `actions/attest-build-provenance`, as #133 named it: the same action behind a wrapper its maintainers no longer recommend for new use.
- A storage record per artifact: one more permission in every caller, for a link in GitHub's UI that nothing reads.
- Keeping `context`, `cache` and `structure-test` as inputs beside `images`: two ways to say one thing, and a caller with two images couldn't give each its own structure test.

## Consequences

- Every caller of the release module adds two permissions, and every caller of `docker-build` moves to `images`, in its #133 step 10 PR. Until then, Renovate's bump to this major waits for TJ.
- A required check named `Docker Build / Docker Build` becomes `Docker Build / Docker Build (<image>)`.
- yggdrasil's own release pushes no image or chart, so the first real attestation comes from a consumer's release. A failure there fails that release's job, and the fix is a patch here.
- A private repo on GitHub Free can't attest ([`docs/DATA.md`](../DATA.md#github)), so its real release would fail at the attest step. No private repo calls the release module on 2026-11-21, so the module doesn't skip it.
