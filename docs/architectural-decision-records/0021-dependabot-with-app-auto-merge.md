# 0021. Dependabot updates actions and tool images weekly, and its patch and minor updates merge themselves as the App

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ. The patch and minor rule is TJ's standard ("I thought we were setting a standard to auto merge patch and minor updates?", hevy-trainer-sync record 0037). Using the App here from the start: "Use the App now", 2026-11-05.
- Issues and PRs: #2, #20
- Cited in code as: decision record 0021, in `.github/dependabot.yml` and `.github/workflows/dependabot-auto-merge.yml`
- Guide: [`docs/CICD.md`](../CICD.md), Dependabot

## Context

Every action is pinned by SHA and every tool image by digest, so nothing moves unless a PR moves it. Merging those PRs by hand doesn't scale, and a merge made with `GITHUB_TOKEN` starts no `on: push` workflow, which would leave a module change merged but never released.

## Decision

- `.github/dependabot.yml` updates `github-actions` and `docker-compose` (the images in `compose.yml`) weekly, each version update waiting seven days after its release (`cooldown`), with titles `build(deps): ...`. pip joins with the first Python code in #4, and `/actions/*` with the first composite action.
- `dependabot-auto-merge.yml` runs for PRs whose author is `dependabot[bot]`, reads the update type with `dependabot/fetch-metadata`, and for `version-update:semver-patch` or `version-update:semver-minor` mints a token from `zimmertr-yggdrasil-bot` with `actions/create-github-app-token`, scoped to this repo with contents, pull requests and workflows write. With it, it arms squash auto-merge and comments on the PR. Majors and digest-only updates wait for TJ.
- `GITHUB_TOKEN` gets only `pull-requests: read`.

## Evidence

- 2026-11-05: hevy-trainer-sync #37 (a minor bump) merged itself under the same rule after #47.
- 2026-11-05: `create-github-app-token` v3.3.0 marks `app-id` deprecated in favour of `client-id`, so the workflow names the App by its public client ID.

## Alternatives rejected

- `AUTO_MERGE_PAT`, as the other repos use: TJ's own token, shown as the author of every merge, and without Workflows permission, so a bump that edits `.github/workflows` would wait.
- Arming the merge with `GITHUB_TOKEN`: the merge would start no release.
- No cooldown on actions: an action is code that runs in CI with a token, so a compromised release is as dangerous as a compromised package.

## Consequences

The private key lives as a Dependabot secret, readable by any Dependabot run here. The job checks the PR's author rather than `github.actor`, which can be whoever re-ran the job.
