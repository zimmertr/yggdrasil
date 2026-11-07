# 0038. A repo moving onto the modules takes a trimmed set of `initialize-project`'s repo files once, and adds the rest as later work reaches it

- Status: Superseded in part by 0041
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, in #7, choosing the trimmed set: "future work on those repos needs to start producing ADRs and other skipped files moving forward. This is a one-time exception to avoid burning tokens generating these"
- Issues and PRs: #7
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "Consumers take a trimmed set of repo files"

## Context

`initialize-project` gives a new repo its `LICENSE`, `.gitignore`, `SECURITY.md`, `CONTRIBUTING.md`, issue templates, a `CLAUDE.md` with an Issues section, and a `docs/` set with decision records. The repos #7 moves onto the modules predate it. #7's inventory found most of them lack five or more of those files, and several hold only STL files, a script, or one README, where a `CONTRIBUTING.md` and a `docs/` set would repeat the README.

## Decision

- In #7, every repo gets `LICENSE`, `.gitignore`, `SECURITY.md`, `.github/ISSUE_TEMPLATE/` and a short `CLAUDE.md` with its Issues section.
- `CONTRIBUTING.md` and `docs/` go only where there is code or CI to describe: Kubernetes-Manifests, TJs-Kubernetes-Service, bluebird-helm, Personal-Website, Mountaineers-Activity-Scraper, Better-Lighter-Pack, Strava-Heatmap-String-Builder and Resume.
- This is once, for #7. Later work on any of these repos writes its decision records and adds the skipped files it needs, and each repo's short `CLAUDE.md` says so.
- A repo with no license takes GPLv3, like TJ's other public repos: Kubernetes-Manifests, Bootstrap-Proxmox and Ender-6-Klipper-Guide. Resume, which is private, stays unlicensed.

## Evidence

- 2026-11-06, #7's inventory: none of the fourteen repos in scope had every file. Kubernetes-Manifests, bluebird-helm and nine smaller repos had no `CLAUDE.md`, and only TJs-Kubernetes-Service had `docs/`.

## Alternatives rejected

- The full set everywhere: pages for repos with nothing to describe, written up front instead of when someone needs them.
- No repo files in #7: the repos would stay without a `CLAUDE.md`, so a session in them would not know how to file an issue or what to keep current.

## Consequences

The smaller repos look thinner than a new repo does. A session working in one reads its `CLAUDE.md`, which tells it to add the records and pages its change needs.
