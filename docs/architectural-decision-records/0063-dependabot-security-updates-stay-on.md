# 0063. Dependabot security updates stay on beside Renovate's vulnerability PRs, because only Dependabot fixes an indirect dependency

- Status: Accepted
- Date: 2026-11-21
- Decider: TJ, 2026-11-21, in #133. Step 16 planned to turn Dependabot security updates off. Shown that only Dependabot fixes an indirect dependency, and that its duplicate of a Renovate fix closes itself: "Lets keep it on then."
- Issues and PRs: #133, #135
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "One YAML file per repo and per org"

## Context

Since [0056](0056-one-renovate-preset-for-every-repo.md), Renovate and Dependabot both read each repo's Dependabot alerts and open a fix. #133 planned to turn Dependabot's security updates off, so that Renovate alone opened fixes and nobody closed a duplicate by hand. Before the change, TJ asked whether security fixes would still arrive.

## Decision

- The repo module keeps `github_repository_dependabot_security_updates` on, as [0043](0043-repo-files-hold-no-security-settings.md) set it, and the org module keeps it on for new repos.
- Renovate keeps opening its own fix for each alert. A direct dependency can get two PRs, and Dependabot closes its own once Renovate's merges.

## Evidence

- 2026-11-21: of the 29 Dependabot alerts ever raised across TJ's unarchived repos, all in bluebird and trailhead, 22 were on indirect dependencies, packages that only a lock file names. None was open.
- 2026-11-21: Dependabot's security PRs fixed three of those indirect alerts by moving the lock file alone: undici (zimmertr/bluebird#818), source-map-js (#650) and brace-expansion (#559). Two others, minimatch in bluebird and trailhead, needed an override written by hand (zimmertr/bluebird#870, zimmertr/trailhead#23).
- 2026-11-21, Renovate's source on main: `lib/workers/repository/init/vulnerability.ts` turns each alert into a package rule that matches by package name, so it applies only to a dependency Renovate extracts from a manifest. Its configuration options no longer include `transitiveRemediation`. So an alert on an indirect npm dependency gets no PR from Renovate.
- 2026-11-21: Dependabot closed zimmertr/bluebird#939 itself, two minutes after Renovate's zimmertr/bluebird#940 merged the same fix: "Looks like opentelemetry-api is up-to-date now, so this is no longer needed." zimmertr/trailhead#43 and #44 were both closed by hand because a third PR, #42, replaced them, not because one duplicated the other.

## Alternatives rejected

- Dependabot's security updates off, Renovate alone (#133's plan): an alert on an indirect dependency would get no PR at all, and nothing would say so.
- Off, plus Renovate's `lockFileMaintenance` to refresh lock files: it isn't known to respect `minimumReleaseAge`, so it could pull in an indirect release younger than the 7-day or 30-day wait ([0062](0062-riskiest-upstreams-wait-30-days.md)).
- Renovate's vulnerability PRs off, Dependabot alone: its PRs don't merge themselves since 0056 removed the auto-merge module, so every direct fix would wait for TJ.

## Consequences

- A direct dependency's fix can open two PRs, one of which closes itself. Each still runs CI and sends a notification.
- An indirect dependency's fix comes only from Dependabot, and waits for TJ to merge it.
- The Dependabot secrets in yggdrasil stay, since a Dependabot PR there still plans.
