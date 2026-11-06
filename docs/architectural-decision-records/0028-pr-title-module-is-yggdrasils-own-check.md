# 0028. The pr-title module is yggdrasil's own PR Title workflow, callable with `workflow_call`

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on #4 item 2.5: "lgtm, continue"
- Issues and PRs: #4, #29
- Cited in code as: decision record 0028, in `.github/workflows/pr-title.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#pr-titleyml)

## Context

#4 planned a separate pr-title module that yggdrasil's own `PR Title` job would call, renaming the required check to `PR Title / PR Title` and changing branch protection to match.

## Decision

`pr-title.yml` keeps its `pull_request` trigger and adds `workflow_call`. yggdrasil runs it directly, and other repos call the same file. It takes no inputs: the types match `defaults/GitVersion.yml`, which every caller shares today.

## Evidence

- 2026-11-05: hevy-trainer-sync's and Bluebird's `GitVersion.yml` use the same three patterns as `defaults/GitVersion.yml`.

## Alternatives rejected

- A separate module file and a yggdrasil caller: a second file, a check rename and a protection change, for the same check.
- A `types` input: no caller needs other types yet.

## Consequences

yggdrasil's own runs test the module, and its required check keeps its name. A caller with its own `GitVersion.yml` and other types needs a `types` input, added then as a minor.
