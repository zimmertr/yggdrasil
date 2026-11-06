# 0036. A decision record is written only for a decision that shapes the system

- Status: Accepted. Supersedes 0017's record for every decision
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, on the end-to-end audit after #4: "Fewer decision records"
- Issues and PRs: none
- Cited in code as: none
- Guide: [`README.md`](README.md#write-a-record)

## Context

By 2026-11-06 there were 34 records, written in two days, for about 850 lines of workflow. Four were partly replaced the day after they were written. Many recorded a module's inputs or the action a step uses, which `docs/CONFIGURATION.md` and the workflow's own comments already explain.

## Decision

- A record is written for a decision that shapes the system: what yggdrasil is and holds, how versions and releases reach consumers, identity and credentials, the security guards, the Terraform design, and how the repo itself is worked on.
- A module's inputs, defaults, the actions it uses and how a step works are not records. They live in `docs/CONFIGURATION.md` and in the workflow's comments, which explain why.
- 0017's rule that every change updates its docs page in the same PR stands.
- Existing records stay as they are.

## Evidence

- 2026-11-06: records 0029 to 0032 were marked "Accepted, except parts 0034 replaces" one day after they were written.

## Alternatives rejected

- Folding the module records into one: it rewrites history for no reader's gain.

## Consequences

Fewer, longer-lived records. A module PR updates `docs/CONFIGURATION.md` and its comments, and needs a record only when it changes one of the areas above.
