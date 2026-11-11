# 0052. The release module pushes to GHCR with the job's token, refuses a version already there, and deploys pin the digest

- Status: Accepted
- Date: 2026-11-10
- Decider: TJ, 2026-11-07 and 2026-11-10, on #9: "I want to move off DockerHUb and to GHCR"; "Refuse, and deploy by digest", after reading what GitHub and the community say about immutable tags.
- Issues and PRs: #9
- Cited in code as: decision record 0052, in `.github/workflows/release.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#releaseyml)

## Context

The release module pushed to Docker Hub with a username and token each caller stored, and relied on Docker Hub's immutable tags: a re-run could not replace a released image, and the scan could trust the tag. GHCR takes the job's own `GITHUB_TOKEN`, but it has no immutable tags.

## Decision

- **Images go to `ghcr.io/<image>`, lowercased**, pushed with `GITHUB_TOKEN`. The caller grants `packages: write`. The `dockerhub-username` and `dockerhub-token` secrets are gone.
- **A version is pushed once.** Build & Push fails before building when `ghcr.io/<image>:<version>` already exists, which is what Docker Hub's immutable tags did.
- **A deploy can pin the digest.** A `deploys` entry with `image` and `digest-set` also writes the image's digest at the release, read from GHCR after the push. What runs then can't change even if someone moves the tag by hand.
- Charts get the refusal only: Argo CD pins a chart by version, not digest. #74 makes the chart push a module.

## Evidence

- 2026-11-10, https://github.com/zimmertr/yggdrasil/pull/73: GHCR took a second push of the same image tag and of the same chart version, each replacing the first. `GITHUB_TOKEN` with `packages: write` pushed both, and each new package started public and linked to the repo ([DATA.md](../DATA.md#ghcr)).
- 2025-10-13, GitHub's Immutable Releases discussion (community discussion 171210): immutable tags are "not yet available in GHCR". The request (discussion 181783) was still open on 2026-09-04.
- GitHub's Container registry docs say to pull by digest for an exact image. A Docker Official Images maintainer, in distribution/distribution-library-image#195: registry tags "are not (and have never been) officially immutable".

## Alternatives rejected

- Accept that a re-run can replace a release: an old run re-run by mistake would rebuild a released version without a word.
- The refusal alone: it stops this module, not a person or another token with write access.
- Stay on Docker Hub, or manage it with Terraform: a stored token per repo, with no per-repo limit (#12).

## Consequences

- A re-run of a build that already pushed fails at the check. Re-run the failed jobs only.
- A deploy that pins the digest changes both lines in each bump PR, and its kustomization names `ghcr.io/...`.
- Packages from a public repo start public, so the scan needs no credential. A private repo's or an org's first package wasn't tried.
