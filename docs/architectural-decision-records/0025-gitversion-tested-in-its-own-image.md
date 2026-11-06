# 0025. GitVersion's rules are tested by a bash script in the pinned GitVersion image, and shellcheck lints every shell script

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, choosing "Bash in GitVersion image" over a pytest image for #4 item 2.1
- Issues and PRs: #4
- Cited in code as: decision record 0025, in `tests/gitversion/test.sh` and the `Makefile`
- Guide: [`docs/DEVELOPMENT.md`](../DEVELOPMENT.md#tests)

## Context

Every release rests on GitVersion reading `GitVersion.yml` the way record 0004 says: only module paths release, the title alone picks the bump, and a skipped commit leaves `Sha` on the last commit that counted. #3 showed that by hand. A test has to hold it on every PR, and again when Dependabot bumps the engine. The test needs git, to build histories, and GitVersion, to read them.

## Decision

- `tests/gitversion/test.sh` builds each case as a fresh made-up history, a minute between commits, and checks GitVersion's `SemVer` and the commit its `Sha` names. It covers yggdrasil's own `GitVersion.yml` and the callers' `defaults/GitVersion.yml`.
- It runs in the `gittools/gitversion` image pinned in `compose.yml`, which already ships git and bash. `make gitversion` runs it, and the `GitVersion Engine` job runs that.
- shellcheck, from the pinned actionlint image, lints every shell script outside the workflows in the `actionlint` job.

## Evidence

- 2026-11-05: `gittools/gitversion:6.8.2` is Ubuntu 24.04 with `/usr/bin/git` and `/usr/bin/bash`, and its CLI prints `{SemVer} {Sha}` in one call with `/output json /format`.
- 2026-11-05: `rhysd/actionlint:1.7.12` ships shellcheck 0.11.0.

## Alternatives rejected

- pytest in an image yggdrasil builds from Python, git and GitVersion: one test runner for the whole repo, but a Dockerfile to maintain from the first PR. The Python harness arrives with the first Python script instead (#4 item 2.2).
- Running GitVersion through `gittools/actions`: the engine would then run on the runner rather than in the pinned image, and the test couldn't run the same way locally (record 0018).

## Consequences

The engine the test runs and the engine the release runs must stay the same version; #4 item 2.4 decides how the release module pins it. A new shell script is added to `SHELL_SCRIPTS` in the `Makefile`, or shellcheck doesn't see it.
