# 0002. Each caller passes its own configuration to a module as inputs

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05: "I recant this. Configuration should probably come from the consumers of yggdrasil as input vars… I want to avoid over engineering here and KISS."
- Issues and PRs: #1, #4
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "Callers bring their own config"

## Context

TJ first asked for as much shared code as possible, down to a central YAML file in yggdrasil describing each repo's pipeline. That would have made yggdrasil hold every consumer's settings, and every change to one repo's pipeline a change to yggdrasil.

## Decision

A module reads everything repo-specific from its `with:` inputs and its `secrets:`. yggdrasil keeps no per-repo pipeline config. The only per-repo data it holds defines the repos and orgs themselves (`repos/`, `orgs/`, 0012).

## Evidence

No dated measurement.

## Alternatives rejected

- A central config file in yggdrasil, read by each module: TJ proposed it, then withdrew it as over-engineering.

## Consequences

Each module documents its inputs in [`docs/CONFIGURATION.md`](../CONFIGURATION.md). Changing a default is a module change and a release; changing one repo's choice is a PR in that repo.
