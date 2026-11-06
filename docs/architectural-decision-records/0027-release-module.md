# 0027. The release module runs GitVersion's image, previews each PR's version, and makes the tag and release in one `gh release create`

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on #4's trimmed plan: "LGTM, continue." The preview replaced a test of GitVersion's rules: "Yup. Please try not to over engineer going forward."
- Issues and PRs: #4, #28
- Cited in code as: decision record 0027, in `.github/workflows/release.yml` and `ci-release.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#releaseyml)

## Context

hevy-trainer-sync's release runs GitVersion through `gittools/actions`, pushes the tag with git from a checkout that keeps its token, then creates the GitHub release. yggdrasil needs the version and release half as a module that works for every caller, and a PR needs to show what its merge will release.

## Decision

- A `Version` job runs `gittools/gitversion:6.8.2`, pinned by digest, in Docker. It reads the caller's root `GitVersion.yml`, or `defaults/GitVersion.yml` from the module's own checkout (0022).
- On a PR, it builds the squash commit the merge will make, the PR's changes on the base branch with the PR title as the message, and versions that. The job summary says "Releases vX.Y.Z." or "Releases nothing: vX.Y.Z is already tagged."
- A `Tag and Release` job runs only on main, outside dry run, and only for a version not yet tagged. `gh release create --target <sha> --generate-notes` makes the tag and the release in one call, with no checkout.
- yggdrasil calls it from `ci-release.yml` with `uses: $/...`, which also makes it the module's test caller.

## Evidence

- 2026-11-05: on #28, the dry run versioned the squash commit as v0.2.0. [`docs/DATA.md`](../DATA.md#github) has the details and the `$/` and actionlint findings.

## Alternatives rejected

- `gittools/actions`: GitVersion's GitHub Actions support takes the branch from the runner's environment, which on a PR is the merge ref, not main. The image sees only the repo.
- Pushing the tag with git: needs a checkout that keeps the token, which `gh release create --target` avoids.
- hevy-trainer-sync's guard that keeps an old release from taking "Latest": it matters only when an older run finishes after a newer one, and releases run one at a time.

## Consequences

Dependabot doesn't see the image pin inside `run:`, so a GitVersion upgrade is a hand edit here. A re-run after a failed release finds the version tagged and does nothing; a tag with no release needs `gh release create` by hand.
