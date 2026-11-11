# 0053. The release module releases only from main's newest commit

- Status: Accepted
- Date: 2026-11-11
- Decider: TJ, 2026-11-10, "Yes" to filing #58 with option A as its recommendation, then 2026-11-11: "start 58".
- Issues and PRs: #58
- Cited in code as: record 0053, in `.github/workflows/release.yml`
- Guide: [`docs/USAGE.md`](../USAGE.md#in-a-consuming-repo), [`docs/CONFIGURATION.md`](../CONFIGURATION.md#releaseyml)

## Context

A caller's `concurrency` group runs one release at a time, and GitHub keeps only the newest waiting run, cancelling the rest. When six Dependabot PRs merged into hevy-garmin-sync within three minutes on 2026-11-10, most merges got no release, and the version went from 0.1.0 to 0.1.6. Re-running the oldest of those runs pushed `zimmertr/hevy-garmin-sync:0.1.0`, then failed in `Tag and Release` with `HTTP 403: Resource not accessible by integration`. The image stayed with no release.

## Decision

- The `Version` job compares the run's commit with main's head, read from the API with the job's own token. When main has moved past the commit, the run releases nothing: build, scan, tag, release and deploy all skip, and the job summary says "Releases nothing: main has moved past this commit, and the release from main's newest commit includes it."
- The check applies only to runs on `refs/heads/main`, so a PR's dry run is unchanged.
- Skipped versions stay skipped. GitVersion counts every merge since the last tag, so the next release carries every change.

## Evidence

- semantic-release does the same: it refuses to publish when the local branch is behind the remote.
- 2026-11-10, https://github.com/zimmertr/hevy-garmin-sync/actions/runs/42876099619: the re-run of an old release that pushed an image and failed at the tag.
- 2026-11-11: v1.0.1 compared with `origin/main`, and a re-run of its release after #79 merged still said "v1.0.1 is already tagged" (https://github.com/zimmertr/yggdrasil/actions/runs/42956464159). For a push, `actions/checkout` sets `origin/main` to the run's own commit, so the clone can't see a newer main. v1.0.2 reads it from the API.

## Alternatives rejected

- Documenting it only: the next re-run of an old release could still push an image with no release.
- Finding the 403's cause and tagging with another token: it would finish a release already behind main, whose deploy PR points production back at an older version.
- Queueing every merge's release: GitHub's `concurrency` keeps at most one run waiting per group.

## Consequences

- A failed release can't be finished by re-running it once main has moved. Release again from main.
- "Re-run failed jobs" on an old run whose `Version` job passed skips the check, so it can still point a deploy back. The docs say not to.
- The cause of the 403 stays unknown.
