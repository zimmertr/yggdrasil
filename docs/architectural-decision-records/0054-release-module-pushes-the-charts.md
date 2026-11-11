# 0054. The release module pushes Helm charts, and a chart module checks them on PRs

- Status: Accepted
- Date: 2026-11-11
- Decider: TJ, 2026-11-10, on #9: "make sure an issue is filed to modularize this and incorporate bluebird-helm". Then 2026-11-11, asked how the bump is shared: "C", the release module pushing the chart itself.
- Issues and PRs: #74, #82
- Cited in code as: decision record 0054, in `.github/workflows/release.yml`, `chart.yml`, `ci-chart.yml` and `ci-release.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#releaseyml), [`docs/CONFIGURATION.md`](../CONFIGURATION.md#chartyml)

## Context

bluebird-helm and hevy-garmin-sync each kept their own copy of three jobs: a chart check on PRs, a chart push after the release, and a job that opened the Kubernetes-Manifests PRs. The third was a copy of the release module's `Deploy Bump` job. Neither repo could use the module's own, because it ran straight after the tag, before a chart existed.

## Decision

- `release.yml` takes a `charts` input, beside `images`. A `Push Chart` job packages each chart at the release's version and pushes it to `oci://ghcr.io/<owner>` under the name in its `Chart.yaml`.
- `Push Chart` runs after `Tag and Release` and before `Deploy Bump`. A chart repo passes its Kubernetes-Manifests bump as `deploys`, like an image repo, and no bump is copied.
- A version already in GHCR is never pushed again. Argo CD pins a chart by version, and GHCR would replace it (record [0052](0052-images-go-to-ghcr-pinned-by-digest.md)).
- With `image` and `digest-set`, the chart ships the app the same release built: its `appVersion` becomes the version, and the image's digest is written into its `values.yaml` before packaging. Without them the chart keeps its `Chart.yaml`'s `appVersion`.
- `helm package --dependency-update` fetches a chart's dependencies from the repositories its `Chart.yaml` names. There is no input for them.
- A dry run packages each chart and pushes nothing.
- `chart.yml` is the PR check: dependencies fetched, `helm lint`, a render with the defaults, then the caller's own renders as a Bash script in `test`, as `docker-build.yml` takes its smoke test.
- `ci-chart.yml` tests `chart.yml` on `tests/chart/`, a chart with one ConfigMap, and `ci-release.yml`'s dry run packages the same chart.

## Evidence

- 2026-11-11, in Docker with Helm v4.3.0: `helm package --dependency-update` and `helm dependency update` fetched bluebird-helm's database subchart with no `helm repo add`, and did nothing for hevy-garmin-sync's chart, which has no dependencies.
- The same day: `helm show chart oci://ghcr.io/zimmertr/hevy-garmin-sync-helm --version 0.3.1` exited 0, and `--version 9.9.9` exited 1.

## Alternatives rejected

- A `chart.yml` that also publishes, calling a `deploy.yml` split out of `release.yml` (#74's option A): modules nested two deep, the deploy token passed down both levels, and each chart repo still running two jobs.
- A copy of the deploy job in `chart.yml` (#74's option B): two copies of the bump in yggdrasil.
- Pushing the chart before the tag, as the images are: a version pushed from a commit whose tag then failed would be kept, because of the skip, for the next commit that gets that version.
- An input for where `appVersion` comes from. bluebird-helm read Bluebird's latest release at package time. Bluebird's release already sets `appVersion` in `Chart.yaml` through a deploy PR, and that PR's merge is what releases the chart.
- A list of `helm template` arguments in place of `test`: bluebird-helm pipes its renders into its own route check, which a list can't say.
- `helm/chart-testing-action`: `ct lint` checks that a chart's version was raised, which these charts would fail because the release sets it, and adds YAML and maintainer checks neither repo runs.

## Consequences

- A release whose chart push failed is finished with "Re-run failed jobs", while it is still main's newest commit. "Re-run all jobs" finds the tag and pushes nothing. The two repos' own jobs read the tag from the commit, so either re-run finished them.
- Helm's version is set by hand in `release.yml` and `chart.yml`: Dependabot doesn't read the `azure/setup-helm` input.
- yggdrasil's CI runs neither the digest write nor the push, which a dry run skips. A caller's release is their test.
