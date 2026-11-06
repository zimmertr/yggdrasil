# 0037. A lint module runs actionlint, zizmor and Semgrep in every repo, in the images `compose.yml` pins

- Status: Accepted. Supersedes 0026 in part
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, in #6, on replacing Bluebird's own workflow and config tests: "We should try and replace them with reusable components in yggdrasil as part of this issue. And then update Bluebird to use them." and, on the plan, "Makes sense to me." On keeping a Python test for the base-image digests: "You keep trying to roll our own hack scripts instead of leaning on existing tools and frameworks."
- Issues and PRs: #6, #7
- Cited in code as: decision record 0037, in `.github/workflows/lint.yml`, `.github/workflows/checks.yml` and `GitVersion.yml`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Branch protection and the checks today

## Context

Record 0026 kept actionlint out of the modules: it was one step, and each repo ran it already. Bluebird has since moved onto the modules (#6), and still checked its workflows and its base-image digests with Python tests of its own, because no repo ran zizmor except yggdrasil. #7 needs the same checks in every other repo.

## Decision

- `.github/workflows/lint.yml` is a module with three jobs, `actionlint`, `zizmor` and `semgrep`, and no inputs. zizmor runs with `--persona=pedantic`, online with the job's read-only token. Semgrep runs one registry rule, `dockerfile.audit.dockerfile-source-not-pinned`, which fails a Dockerfile `FROM` that has a tag but no digest. A `FROM` with no tag passes it; for an image that ships, the `docker-build` module's hadolint refuses that first (DL3006).
- All three run in the images `compose.yml` pins, through `docker compose`, read at the commit the caller pinned (record 0022). Callers, yggdrasil's CI and `make actionlint` / `make zizmor` / `make semgrep` run one image set, which Dependabot moves.
- `compose.yml` is a module path, so a tool bump releases a patch and reaches callers with their next pin bump.
- yggdrasil's own `checks.yml` calls the module from the PR's copy instead of running the tools itself, which tests every change to the module before it releases. The required checks become `Lint / actionlint`, `Lint / zizmor` and `Lint / semgrep`.

## Evidence

- 2026-11-06: zizmor 1.16.0, run with `--persona=pedantic` on a workflow holding `run: echo ${{ github.sha }}`, flagged it as `template-injection`, so the module replaces Bluebird's `test_no_expression_is_pasted_into_a_script`.
- 2026-11-06: hadolint, Trivy 0.69.1 and Checkov 3 don't check that a Dockerfile's base image carries a digest, and frizbee 0.1.11's `--error` exited 0 after rewriting an unpinned image. Semgrep 1.140.0's registry rule does: on `FROM python:3.15-alpine` it reported the line and exited 1, and over Bluebird it scanned `Dockerfile` and `fill/Dockerfile` and found nothing.
- 2026-11-06, #7's inventory: Semgrep 1.183.0's rule, run in Docker, flagged `FROM python:3.12-slim` and `FROM nginx:latest`, and passed `FROM python`, `FROM build` (an earlier stage) and `FROM scratch`. Semgrep's `missing-image-version` caught `FROM python` but also flagged `FROM build`. hadolint 2.12.0 flagged `FROM python` (DL3006) and `nginx:latest` (DL3007), and passed the stage and `scratch`. The same day, TJ chose to keep the one rule and correct this record's wording, which had said the rule fails any `FROM` without a digest.

## Alternatives rejected

- `zizmorcore/zizmor-action` and a community actionlint action: two more pins that track the tools apart from `compose.yml`, so CI and a local run could disagree (record 0018).
- `docker run` with the image digests written in the module: Dependabot doesn't read `run:` lines, so the pins would never move.
- Keeping record 0026's "no actionlint module": every repo would copy two jobs and pin the images itself.
- Bluebird's own Python test for the digests: custom code for a rule a maintained tool already holds.
- Semgrep's full registry rulesets: findings nobody asked for. One rule is the gap the other tools leave.

## Consequences

- A new zizmor release can add findings in every caller at once, on the pin bump that brings it. The fix is in the caller's workflow, or an ignore with its reason.
- A tool bump in `compose.yml` releases yggdrasil even when only `lychee` moved.
- The `semgrep` job needs semgrep.dev to fetch its rule, so an outage there fails it.
