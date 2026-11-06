# 0025. No breaking-change check: each caller's own CI catches a breaking release

- Status: Accepted. Drops the breaking-change check from 0004 and 0011
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on #4 item 2.2: "Well, remember YAGNI and Kiss?"
- Issues and PRs: #4
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "Guardrails are CI checks"

## Context

Records 0004 and 0011 planned a CI check that compares each module's `workflow_call` inputs and outputs with the last release, and fails a breaking change whose PR title lacks `!`. No maintained tool does that, so it would be code yggdrasil writes and keeps.

## Decision

There is no breaking-change check. A change that breaks a caller still carries `!` in its PR title, and the `PR Title` job still reads it.

## Evidence

- 2026-11-05: a search found no action or tool that compares a reusable workflow's inputs between two tags.
- A release that removes an input, or adds a required one, makes the caller's workflow invalid. The caller's Dependabot or Renovate bump PR then fails its own CI, so it never merges itself (0023).

## Alternatives rejected

- A short `yq` script in a pinned image: less code than the planned Python, but still a check of our own for a failure the callers' CI already stops.

## Consequences

A forgotten `!` shows up as failed bump PRs in the callers rather than as a failed check in yggdrasil. The fix is a new release, with `!` if the break stays. A change in behaviour that keeps every input is caught by neither.
