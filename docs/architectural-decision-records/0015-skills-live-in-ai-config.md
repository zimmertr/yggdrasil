# 0015. Shared skills live only in zimmertr/ai-config, and a repo-specific skill lives only in its repo

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, when #2 planned a copy of `create-issue` here: "We need to define the skills in one place and one place only. Not in each repo." Then, after reading Anthropic's guidance: "Lets leave bluebird's skills in the repo, and ensure they're under .claude/skills."
- Issues and PRs: #2, #14, zimmertr/ai-config#4
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "Skills live in zimmertr/ai-config only"

## Context

`initialize-project` used to copy `create-issue` into each new repo so its `CLAUDE.md` could rely on it. The copies drift.

## Decision

A skill that works in any repo, such as `create-issue`, lives only in zimmertr/ai-config, linked into `~/.claude/skills` today. A skill about one repo's code lives only in that repo's `.claude/skills/`. Nothing is copied. yggdrasil's `CLAUDE.md` points at `create-issue` in ai-config.

## Evidence

- 2026-11-05: the copies of `create-issue` in Bluebird and hevy-trainer-sync had drifted to 147 and 108 lines (zimmertr/ai-config#4).
- 2026-11-05: Claude Code's skills docs (https://code.claude.com/docs/en/skills) load a project's skills only in sessions in that repo, keep every skill's description in context, and let a personal skill win over a project skill of the same name.

## Alternatives rejected

- A copy of `create-issue` under `.claude/skills/` here: the plan's first version, dropped by TJ.
- Moving Bluebird's repo-specific skills to ai-config: their descriptions would sit in every session's context, in repos where they can't run.

## Consequences

A session in yggdrasil needs ai-config's skills installed. zimmertr/ai-config#4 turns ai-config into a plugin marketplace that yggdrasil will add in its `.claude/settings.json`, and #14 asks whether ai-config later moves into yggdrasil.
