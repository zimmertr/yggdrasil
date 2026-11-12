# 0057. An image's SBOM is the attestation BuildKit puts on it, and no release carries an SBOM file

- Status: Accepted. Supersedes 0001 in part: the SBOM module
- Date: 2026-11-11
- Decider: TJ, 2026-11-11, on keeping the attestation and attaching no release file: "I agree with your direction"
- Issues and PRs: zimmertr/ai-config#13
- Cited in code as: none
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#releaseyml), the release module's build bullet

## Context

[0001](0001-one-public-gpl-3-monorepo.md) and the PRD said an SBOM module would follow the project. zimmertr/ai-config#13 asked whether each release should also attach an SPDX or CycloneDX file, and whether each repo should keep a `docs/SBOM.md`. By 2026-11-11 the release module already built every image with `sbom: true`, so every caller's image carried an SBOM with no work in the caller.

## Decision

- The SBOM is the SPDX attestation BuildKit adds to each image, one per platform, through the release module's `sbom: true`. `docker buildx imagetools inspect <image>:<version> --format '{{ json .SBOM }}'` reads it.
- No GitHub release carries an SBOM file, and no repo keeps a `docs/SBOM.md`.
- There is no SBOM module.

## Evidence

- 2026-11-05: Bluebird v0.132.17 and hevy-trainer-sync v0.1.8 had no release assets, and nothing of TJ's reads one (zimmertr/ai-config#13).
- 2026-11-11: `ghcr.io/zimmertr/bluebird:0.135.0` carried an SPDX 2.3 SBOM for `linux/amd64` and for `linux/arm64`, 96 packages each. `ghcr.io/zimmertr/hevy-garmin-sync:0.9.0` carried the same for both platforms, 127 packages each.

## Alternatives rejected

- Attach the attestation's SPDX document to each release: one file per image and platform (four for Bluebird), and a registry read in the release job, for no reader. The release is immutable, so the files would have to be ready before `gh release create`.
- Generate a CycloneDX file with Trivy and attach that: a second SBOM beside the attestation, from a different tool, and the two can disagree.
- A separate SBOM module ([0001](0001-one-public-gpl-3-monorepo.md)): the release module already makes the SBOM where the image is built.

## Consequences

- Every image the release module builds carries its SBOM in the registry, beside its provenance. A tool that reads only release assets finds nothing.
- A repo that ships no image has no SBOM from yggdrasil. GitHub's dependency graph exports one for it.
- License questions stay in each repo's `NOTICES.md` and the license file its image builds.
