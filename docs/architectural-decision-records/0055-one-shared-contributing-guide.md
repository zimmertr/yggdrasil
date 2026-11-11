# 0055. One shared `CONTRIBUTING.md`, and a repo with its own process keeps its own

- Status: Accepted. Supersedes 0038 and 0041 in part: the contributing guide
- Date: 2026-11-11
- Decider: TJ, 2026-11-06, taking the guide out of #43: "add an issue to yggdrasil to define one and ship it out later. Possibly based on Bluebirds. But we need there to be a generic one for most repos, and tailored ones for real active projects like Bluebird and TKS". Then 2026-11-11, on the five guides to keep: "We can keep these then", and on moving bluebird-helm to the shared guide and deleting Resume's: "Agree".
- Issues and PRs: #44, #86
- Cited in code as: record 0055, in `community-health-files/CONTRIBUTING.md`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "One source for the community health files"

## Context

[0038](0038-consumers-take-a-trimmed-set-of-repo-files.md) gave each repo with code or CI its own `CONTRIBUTING.md`, and [0041](0041-one-source-for-community-health-files.md) left the guide out of the shared files. On 2026-11-11, eleven of the repos Terraform manages carried one, and the rest had none.

## Decision

- `community-health-files/CONTRIBUTING.md` is the guide for every repo without its own. Terraform writes it to the root of each owner's `.github` repo with the other shared files.
- It says only what holds in any repo. A step that needs a build, a `Makefile`, tests or a `docs/` folder says so.
- A repo keeps its own guide when it has a process the shared one can't describe. Five do: bluebird, TJs-Kubernetes-Service, Kubernetes-Manifests, hevy-garmin-sync and yggdrasil.
- Personal-Website, Mountaineers-Activity-Scraper, Better-Lighter-Pack, Strava-Heatmap-String-Builder, bluebird-helm and Resume delete theirs, one PR each.

## Evidence

- 2026-11-11: Personal-Website's, Mountaineers-Activity-Scraper's, Better-Lighter-Pack's and Strava-Heatmap-String-Builder's guides share their steps almost word for word: branch from `main`, one change per PR, the title format, the PR's checks. What else they say is already elsewhere: Strava-Heatmap-String-Builder's README warns that Strava disables an account that signs in too often, and Mountaineers-Activity-Scraper's `.gitignore` holds its credentials file.
- 2026-11-11: bluebird-helm's guide adds one rule to those steps, to change the chart's README when a value changes. Resume is private, so nobody outside reads its guide.
- 2026-11-11: the kept guides name things the shared one can't: where a new app goes in Kubernetes-Manifests and what a new top-level folder needs, hevy-garmin-sync's test rules (`unittest` only, no network, coverage aimed at 100%), yggdrasil's zizmor audits and the `!` for a change that breaks a caller. TJ named bluebird and TJs-Kubernetes-Service when asking for the shared guide.

## Alternatives rejected

- A template Terraform fills in for each repo: Terraform would write into every repo, which 0041 kept to the `.github` repos, and each repo's values would need keeping true.
- Keeping the eleven copies: the generic ones drift, and a repo with none stays without.

## Consequences

- GitHub swaps the whole file, so a repo's own guide is complete in itself and doesn't follow changes to the shared one.
- Every repo of an owner without its own guide shows the shared one, the ones Terraform doesn't manage included.
- A new repo needs no `CONTRIBUTING.md`. `initialize-project` says so (zimmertr/ai-config).
