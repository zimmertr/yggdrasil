# 0017. Every change updates its docs page in the same PR, and every decision gets a record here

- Status: Accepted, except a record for every decision, which 0036 narrows
- Date: 2026-11-05
- Decider: TJ's standard for new projects, in zimmertr/ai-config's `initialize-project` (`references/docs.md`), applied here by #2.
- Issues and PRs: #2
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Documentation

## Context

yggdrasil is read by people and by agents working in twenty other repos. Without a page per topic and a record per decision, every session would have to read the workflows and the Terraform to learn why they are the way they are.

## Decision

- Each page in `docs/` owns one topic, and the table in `CLAUDE.md` says which page owns what. A change that makes a page untrue fixes it in the same PR.
- Every decision gets a record in this folder, in the PR that makes it, and the `CLAUDE.md` rule or docs section that states it links to the record.
- No page restates a number the code or a provider defines. It gives the reason and links to where the number lives.
- No doc contains an em dash. The policy test (#2 item 0.5) holds this.

## Evidence

No dated measurement.

## Alternatives rejected

- Docs only in the README: the README is TJ's, in TJ's own words, and kept short.

## Consequences

A PR is not done until its docs and its record are in it. The records here start at 0001; decisions made earlier in the consuming repos keep their own records there.
