# 0064. A cache-cleanup module deletes a PR's Actions caches when it closes, as a module of its own

- Status: Accepted
- Date: 2026-11-21
- Decider: TJ, 2026-11-21, in #133: "Cache cleanup is its own module, so no caller breaks."
- Issues and PRs: #133
- Cited in code as: none
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#cache-cleanupyml)

## Context

GitHub scopes an Actions cache to the ref that wrote it and keeps a closed PR's until it goes seven days unread, or until the repo passes its 10 GB budget and the oldest read is evicted first. Only Bluebird deleted a closed PR's caches, with its own `cache-cleanup.yml`. The `docker-build` and `pr-preview` modules, and the release module's QEMU step, write caches in other repos too.

## Decision

- `.github/workflows/cache-cleanup.yml` is a module: on `pull_request: closed`, one job deletes every cache on `refs/pull/<number>/merge`. It asks for `actions: write` and nothing else, and takes no inputs.
- It is a module of its own, not a job in `docker-build` or `pr-preview`, so no existing caller has to grant a new permission or add a trigger.
- yggdrasil runs the same file on its own PRs, the way `pr-title.yml` is both yggdrasil's check and a module.
- `gh cache delete --all --ref --succeed-on-no-caches` does the deleting, in place of Bluebird's loop over `gh cache list` (record [0034](0034-community-actions-over-shell.md)).

## Evidence

- 2026-09-15, Bluebird #368: 428 caches, 3.40 GB, belonged to closed PRs while the repo's caches totalled 10.73 GB and GitHub was evicting.
- 2026-11-21: yggdrasil held one 31 MB cache, `docker.io--tonistiigi--binfmt-latest-linux-x64`, for each of its closed PRs from #118 to #136, and three (169 MB) for #135.
- 2026-11-21, `gh cache delete --help` (gh 2.102.0): `--all` "can be used with --ref to delete all caches for a specific ref", and `--succeed-on-no-caches` returns 0 when there are none.

## Alternatives rejected

- A job in `docker-build` or `pr-preview`: each caller would have to add `closed` to its triggers and grant `actions: write`, so the release would break callers that didn't.
- Bluebird's loop, ported as is: about fifteen lines of shell for what one `gh` command does.

## Consequences

- A repo deletes its PR caches only once it calls the module (#133 step 10).
- yggdrasil's own closed PRs test the module, so a broken release shows on the next close.
