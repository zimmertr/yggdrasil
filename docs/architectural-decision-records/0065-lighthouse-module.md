# 0065. A lighthouse module audits the PR's image with treosh/lighthouse-ci-action and the runner's own Chrome

- Status: Accepted
- Date: 2026-11-21
- Decider: TJ, 2026-11-21, in #133. Asked whether the module should run Lighthouse CI's own Docker image, as #133 step 5 planned, or treosh/lighthouse-ci-action with the runner's Chrome, after Lighthouse CI's advice against its image: "treosh action".
- Issues and PRs: #133
- Cited in code as: decision record 0065, in `.github/workflows/lighthouse.yml` and `.github/workflows/ci-lighthouse.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#lighthouseyml)

## Context

Bluebird and trailhead each ran their own `Lighthouse Budgets` job against the image their PR built. Bluebird used treosh/lighthouse-ci-action with Chrome on the runner, and its budgets are a required check. trailhead ran `npx @lhci/cli` inside `zenika/alpine-chrome`, fetching the CLI from npm on every run. #133 step 5 planned one module running Lighthouse CI in an image `compose.yml` pins, as `lint` runs its tools, with treosh as the fallback.

## Decision

- `.github/workflows/lighthouse.yml` is a module. It loads the `<repo name>-image` artifact the docker-build module saves, serves the image on the caller's `port`, waits for `health-path` with curl's own retries, and runs treosh/lighthouse-ci-action with the caller's `config`.
- Lighthouse runs with the runner's Chrome, not in a container, and has no `make` target.
- The caller's config holds the URLs and the assertions. The module takes no URL.
- `ci-lighthouse.yml` tests it on `tests/lighthouse/`, a static page that BusyBox's httpd serves.

## Evidence

- 2026-11-21, Lighthouse CI's `docs/recipes/docker-client/README.md`: "we **strongly advise against using this Docker image when you have the ability to install Chrome directly**", because container resources make performance numbers volatile.
- 2026-10-06, Bluebird's `.github/lighthouserc.js`: its budgets were read off 12 CI runs, 36 audits, with treosh on the runner, before its gate became required.
- 2026-11-21: `patrickhulce/lhci-client` 0.16.1, the image that README publishes, was pushed on 2026-11-11, so the container option was current. It lost on the advice above, not on age.

## Alternatives rejected

- Lighthouse CI's image, pinned in `compose.yml`: one image for CI and a local run, against Lighthouse CI's own advice, and Bluebird's timing budgets would have needed measuring again.
- `npx @lhci/cli` in a Chrome image, as trailhead did: the CLI comes from npm on each run, outside any pin Renovate moves.

## Consequences

- A caller can't run its Lighthouse audit through a yggdrasil `make` target. trailhead keeps its own target for local runs if it wants one.
- trailhead's numbers move from a container to the runner when it switches (#133 step 10), so its timing budgets may need a fresh measurement.
- Lighthouse's version moves with the action's pin, which Renovate updates.
