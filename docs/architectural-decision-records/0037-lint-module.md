# 0037. A lint module runs actionlint and zizmor in every repo, in the images `compose.yml` pins

- Status: Accepted. Supersedes 0026 in part
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, in #6, on replacing Bluebird's own workflow and config tests: "We should try and replace them with reusable components in yggdrasil as part of this issue. And then update Bluebird to use them." and, on the plan, "Makes sense to me."
- Issues and PRs: #6, #7
- Cited in code as: decision record 0037, in `.github/workflows/lint.yml`, `.github/workflows/checks.yml` and `GitVersion.yml`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Branch protection and the checks today

## Context

Record 0026 kept actionlint out of the modules: it was one step, and each repo ran it already. Bluebird has since moved onto the modules (#6), and still checked its workflows with a Python test of its own, because no repo ran zizmor except yggdrasil. #7 needs the same check in every other repo.

## Decision

- `.github/workflows/lint.yml` is a module with two jobs, `actionlint` and `zizmor`, and no inputs. zizmor runs with `--persona=pedantic`, online with the job's read-only token.
- Both run in the images `compose.yml` pins, through `docker compose`, read at the commit the caller pinned (record 0022). Callers, yggdrasil's CI and `make actionlint` / `make zizmor` run one image set, which Dependabot moves.
- `compose.yml` is a module path, so a tool bump releases a patch and reaches callers with their next pin bump.
- yggdrasil's own `checks.yml` calls the module from the PR's copy instead of running the two tools itself, which tests every change to the module before it releases. The required checks become `Lint / actionlint` and `Lint / zizmor`.

## Evidence

- 2026-11-06: zizmor 1.16.0, run with `--persona=pedantic` on a workflow holding `run: echo ${{ github.sha }}`, flagged it as `template-injection`, so the module replaces Bluebird's `test_no_expression_is_pasted_into_a_script`.
- 2026-11-06: hadolint, Trivy 0.69.1 and Checkov 3 don't check that a Dockerfile's base image carries a digest, and frizbee 0.1.11's `--error` exited 0 after rewriting an unpinned image. The module doesn't try to cover that check.

## Alternatives rejected

- `zizmorcore/zizmor-action` and a community actionlint action: two more pins that track the tools apart from `compose.yml`, so CI and a local run could disagree (record 0018).
- `docker run` with the image digests written in the module: Dependabot doesn't read `run:` lines, so the pins would never move.
- Keeping record 0026's "no actionlint module": every repo would copy two jobs and pin the images itself.

## Consequences

- A new zizmor release can add findings in every caller at once, on the pin bump that brings it. The fix is in the caller's workflow, or an ignore with its reason.
- A tool bump in `compose.yml` releases yggdrasil even when only `lychee` moved.
