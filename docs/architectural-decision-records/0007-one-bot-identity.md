# 0007. Automation writes as the GitHub App zimmertr-yggdrasil-bot, with a token minted per run, and yggdrasil has no PAT

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, 2026-11-05: "I like the idea of a yggdrasil-bot app and eliminating the need for a PAT if no longer necessary." Then, on yggdrasil's own auto-merge: "Use the App now".
- Issues and PRs: #1, #2, #3, #12, #13
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "One bot identity"

## Context

TJ's automation ran on personal tokens: `AUTO_MERGE_PAT` per repo and `GH_PAT` on Bluebird. Terraform would need write access to every repo and org TJ owns, and a fine-grained PAT binds to one owner and expires.

## Decision

The GitHub App `zimmertr-yggdrasil-bot` (App ID 5636772), owned by `zimmertr` and installed on every owner yggdrasil manages, is the one identity automation writes as. Each run mints a short-lived token with a SHA-pinned `actions/create-github-app-token`. yggdrasil's own Dependabot auto-merge uses it from the start, through the Dependabot secret `YGGDRASIL_BOT_PRIVATE_KEY` and the App's public client ID (0021). A PAT comes back only if #3 proves one is needed.

## Evidence

- 2026-11-05: `gh api apps/zimmertr-yggdrasil-bot` shows the permissions in [`docs/CONFIGURATION.md`](../CONFIGURATION.md#the-app), and TJ accepted them on all six installations.
- 2026-11-05: the Bluebird-Forecast org caps a fine-grained PAT at 366 days (zimmertr/bluebird#311).

## Alternatives rejected

- A dedicated yggdrasil PAT: TJ's first idea. It binds to one owner, expires, and shows TJ as the author of every automated PR.
- Keeping `AUTO_MERGE_PAT` for yggdrasil until #12: it has no Workflows permission, so bumps that edit workflows would not merge themselves.

## Consequences

A caller can pass only stored secrets to a reusable workflow, never a token it minted, so modules that write will take optional App secrets (#12). The App holds Administration write on every repo, so its key is the most sensitive secret TJ has; #13 tracks a read-only App for plans. Never read or print the key.
