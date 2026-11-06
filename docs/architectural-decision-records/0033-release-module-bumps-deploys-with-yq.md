# 0033. The release module points each deploy repo at the release with `yq`, through one self-merging PR per file

- Status: Accepted
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, on #4 item 2.13: "yq, accept blank lines"
- Issues and PRs: #4
- Cited in code as: decision record 0033, in `.github/workflows/release.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#releaseyml)

## Context

hevy-trainer-sync bumps one `newTag` line in Kubernetes-Manifests with its own Python script. Bluebird bumps its `newTag` with `kustomize edit set image` and its chart's `appVersion` with `sed`. Each opens a PR on a fixed branch and arms auto-merge, and each skips the bump when a newer release exists.

## Decision

- One `deploys` input lists every file, each with its repo, file, `yq` path, branch and title. Both bumps are the same job: set one value to the version, open or update the PR, arm auto-merge.
- `yq`'s own action sets the value, and `yq -e` fails the job when the path matches nothing. The action pins its image by digest.
- `peter-evans/create-pull-request` makes the branch, the commit, the push and the PR, or edits the PR already open. The checkout keeps no credential; the action pushes with its own `token`. The one step left in shell arms auto-merge, with a plain merge when the checks are already green.
- The job runs after the release, because bluebird-helm's release reads Bluebird's latest release. For a Kubernetes-Manifests bump that costs the few seconds the release takes.
- The newer-release check sorts every release tag by version, so it doesn't depend on which release GitHub marks Latest.
## Evidence

- 2026-11-06: `yq` 4.54.1 on a copy of Kubernetes-Manifests' `misc/hevy2garmin/kustomization.yml` changed the one `newTag` and dropped the file's two blank lines. Every comment stayed. On bluebird-helm's `charts/bluebird/Chart.yaml` it changed only `appVersion`, quotes kept.
- 2026-11-06: `kustomize edit set image` (5.4.3) on the same kustomization re-indented both lists, sorted the images, moved both image comments above `images:`, and added `newName`, `apiVersion` and `kind`.
- 2026-11-06: `yq -e '(<path>) == strenv(VERSION)'` exits 1 with "no matches found" on a path that matches nothing, and prints `true` on the bumped file.

## Alternatives rejected

- `kustomize edit set image`: it rewrites the whole file (above).
- `yq` with a diff and patch to keep the blank lines: the lines go once, and every later bump changes one line.
- hevy-trainer-sync's Python script: a module carries no Python (0026).
- The clone, push and PR create-or-edit in shell, as both repos do today: create-pull-request does all of it, maintained and tested by others. TJ, 2026-11-06: "Aren't we supposed to be using existing frameworks instead of rebuilding everything from scratch for this project?"

## Consequences

The first bump of a file removes its blank lines. The job runs first in #5.
