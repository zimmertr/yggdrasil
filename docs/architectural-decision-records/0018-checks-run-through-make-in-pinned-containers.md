# 0018. Every check runs through a make target in a container pinned by digest, the same way locally and in CI

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ's standard (global rules 8 and 9, and `initialize-project`'s `references/project.md`), applied by #2 item 0.4. The `compose.yml` file is the agent's choice in this PR.
- Issues and PRs: #2
- Cited in code as: none
- Guide: [`docs/DEVELOPMENT.md`](../DEVELOPMENT.md), Commands

## Context

Nothing may build, run or test on TJ's workstation, and CI is the test runner. A check that runs one way in CI and another way locally can pass in one place and fail in the other.

## Decision

- Every check is a `make` target: `test`, `lint`, `actionlint`, plus `test-one`, `coverage-summary` and `lock`. CI's jobs call the same targets.
- Each target runs in a container from `compose.yml`, where every tool image is pinned by tag and digest: Python 3.13, ruff, and actionlint (which bundles shellcheck).
- The Python test tools install from `requirements-dev.txt`, a lock with hashes compiled from `requirements-dev.in` by `make lock`, and every install passes `--require-hashes`.

## Evidence

- 2026-11-05: the first run on this PR passed `test` (48 tests) and `actionlint` through the make targets, and `Lint` caught two long lines. The containers ran unchanged on GitHub's runners.

## Alternatives rejected

- Pinning the images in the Makefile, as hevy-trainer-sync does: Dependabot doesn't read Makefiles, so the pins would never move. `compose.yml` is a file Dependabot's `docker-compose` updates can read (#2 item 0.8 confirms they do).
- `actions/setup-python` in CI and Docker locally: two ways to run the same suite.

## Consequences

Each CI job pulls its images, which adds a few seconds. A new tool means a new service in `compose.yml`, pinned by digest, and a new target.
