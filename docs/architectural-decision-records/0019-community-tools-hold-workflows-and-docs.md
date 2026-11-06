# 0019. zizmor, lychee and a grep hold every workflow and doc to the repo's rules, instead of a custom check

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on a first version of #18 that did this in about 400 lines of custom Python: "We should always take advantage of existing frameworks where possible. They are community maintained and tested." On the one rule no tool covers: "A is fine."
- Issues and PRs: #2, #18
- Cited in code as: decision record 0019, in `Makefile`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Working in this repo

## Context

yggdrasil's workflows become every consumer's workflows (0023), so a weak pattern here spreads to twenty repos. #2 item 0.5 listed the rules: SHA pins with a version comment, no `${{ }}` inside `run:`, a timeout on every job, checkouts without credentials, no `pull_request_target`, working doc links, and no em dashes.

## Decision

| Rule | Held by |
|---|---|
| Every `uses:` pinned to a full SHA | zizmor `unpinned-uses` (its default policy hash-pins every action) |
| The `# vX.Y.Z` comment present and matching the SHA | zizmor `ref-version-mismatch`, with the pedantic persona |
| No `${{ }}` inside `run:` | zizmor `template-injection`, with the pedantic persona |
| Checkouts set `persist-credentials: false` | zizmor `artipacked` |
| No `pull_request_target` | zizmor `dangerous-triggers` |
| Relative doc links and their headings resolve | lychee, offline, with `--include-fragments` |
| No em dash in a doc | `grep` in `make em-dash` |

zizmor runs with `--persona=pedantic` over the whole repo, so it also checks `permissions:`, cache poisoning, `GITHUB_ENV` writes and the rest of its audits, and later `dependabot.yml`'s cooldowns. In CI it gets the job's read-only token, which adds its online audits (known vulnerable actions, impostor commits).

The timeout rule is dropped: no tool checks it, and the modules set their own.

## Evidence

- 2026-11-05: zizmor v1.32.0's audit docs list each audit above, and say a missing version comment and every `${{ }}` in `run:` are flagged only under the pedantic persona.
- 2026-11-05: each pinned image was run over a scratch directory that broke every rule. zizmor flagged `pull_request_target`, a tag-pinned checkout, two checkouts that kept credentials, and `${{ }}` in `run:`. Online it also flagged a SHA borrowed from another action (`impostor-commit`), a missing version comment (exit 12) and a wrong one (exit 13). lychee flagged a missing file and a missing heading (exit 2). The em dash check flagged the dash (exit 1).
- 2026-11-05: offline, zizmor did not flag the missing or wrong version comment. The comment checks need its online mode, which CI has and a local run without `GH_TOKEN` doesn't.
- 2026-11-05: the first em dash check used Alpine's BusyBox `grep`, which has no `--include`. It errored, `!` turned the error into a pass, and CI passed with nothing checked. It now runs GNU `grep` on Debian, and only "no match" passes.
- 2026-11-05: over an empty directory, zizmor and actionlint failed (exit 3), but lychee passed (exit 0) with nothing checked, and so would the grep. Both doc checks now also name `README.md` and `CLAUDE.md`, so a missing file fails them instead (lychee exits 1).

## Alternatives rejected

- `scripts/check_policy.py`, a custom check with 49 tests: it worked, but it re-implemented zizmor's audits more weakly (a substring match for template injection, no idea which inputs an attacker controls) and missed everything else zizmor checks. TJ rejected it.
- A small custom check for timeouts alone: GitHub's own 360-minute cap bounds a hung job, and a review catches a module without a timeout.

## Consequences

A finding is fixed in the workflow, or silenced in a `zizmor.yml` with its reason. A new zizmor release can add findings, which shows up as a failing Dependabot bump of its image in `compose.yml`.
