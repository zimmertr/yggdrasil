# 0010. Terraform manages settings, never a repo's files, and plans run only on yggdrasil's own branches

- Status: Superseded in part by 0041
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on the private repos: "If there is no risk of exposing the contents of the repos, lets include them. Otherwise, leave them out."
- Issues and PRs: #8, #13
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "The repo is public" and "No `pull_request_target`"

## Context

yggdrasil is public, and it manages two private repos, Email-Infrastructure and Resume. Plans run with the App's token, which can change any managed repo.

## Decision

- Terraform manages repo settings and never a repo's existing files. It only creates a new repo from the template. So the private repos' names, descriptions and settings appear here, never their contents.
- Plans run only on PRs from yggdrasil's own branches. A fork's PR gets no secrets.
- No workflow uses `pull_request_target`.

## Evidence

No dated measurement.

## Alternatives rejected

- Leaving the private repos out: their settings would stay unmanaged, and settings alone expose nothing TJ wanted hidden.
- `pull_request_target`, to plan fork PRs: it runs a fork's code with the base repo's secrets.

## Consequences

The policy test (#2 item 0.5) fails any `pull_request_target`. An outside contributor's PR can't show a plan; TJ re-pushes it to a branch here when one is needed.
