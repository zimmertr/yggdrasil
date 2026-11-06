# 0018. Every check runs through a make target in a container pinned by digest, the same way locally and in CI

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ's standard (global rules 8 and 9, and `initialize-project`'s `references/project.md`), applied by #2 item 0.4.
- Issues and PRs: #2
- Cited in code as: decision record 0018, in `Makefile`
- Guide: [`docs/DEVELOPMENT.md`](../DEVELOPMENT.md), Commands

## Context

Nothing may build, run or test on TJ's workstation, and CI is the test runner. A check that runs one way in CI and another way locally can pass in one place and fail in the other.

## Decision

- Every check is a `make` target (`actionlint`, `zizmor`, `docs`, and `check` for all three), and CI's jobs call the same targets.
- Each target runs in a container from `compose.yml`, where every tool image is pinned by tag and digest.
- A tool is added as one more service in `compose.yml` and one more target. The Python test harness (a hashed lock, ruff, coverage, a `test` job) arrives with the first Python code, in #4.

## Evidence

- 2026-11-05: the first runs on #18 passed through the make targets, unchanged on GitHub's runners.

## Alternatives rejected

- Pinning the images in the Makefile, as hevy-trainer-sync does: Dependabot doesn't read Makefiles, so the pins would never move. `compose.yml` is a file Dependabot's `docker-compose` updates can read (#2 item 0.8 confirms they do).
- Calling each tool's own GitHub Action in CI and Docker locally: two ways to run the same check.
- A Python harness now, with no Python code to test: an empty `test` job.

## Consequences

Each CI job pulls its image, which adds a few seconds. Local runs need Docker and nothing else.
