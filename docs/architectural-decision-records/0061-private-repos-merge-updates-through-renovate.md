# 0061. A private repo's updates below a major merge themselves, through Renovate's own merge once every check passes

- Status: Accepted. Supersedes 0039 in part: a private repo's updates no longer wait for TJ
- Date: 2026-11-16
- Decider: TJ, 2026-11-16: "Yes for private repos/platformAutoMerge: false if that lest us get these dependency PRs through in private repos automatically. I set all of this up to have standardized modular CI that takes care of everything, nto to review 15 more PRs every week"
- Issues and PRs: none
- Cited in code as: record 0061, in `defaults/renovate-private.json`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "A private repo requires nothing"

## Context

[0039](0039-private-repos-run-the-checks-without-requiring-them.md) left a private repo with no auto-merge, because GitHub Free gives it no required checks, and GitHub's auto-merge waits only for required ones. So every update in Resume, hevy-app-audit and homelab-ipam waited for TJ, and Resume's `.github/renovate.json` turned `automerge` off for every package. Renovate can merge a PR itself instead of handing it to GitHub, and then it reads every check on the PR's newest commit, required or not.

## Decision

- `defaults/renovate-private.json` extends `defaults/renovate.json` and sets `platformAutomerge: false`.
- A private repo's `.github/renovate.json` extends `github>zimmertr/yggdrasil//defaults/renovate-private` in place of the shared preset, and keeps no `automerge` rule of its own.
- So its updates below a major merge themselves on Renovate's first run after every check passes, and a major or a Python minor waits for TJ, as in a public repo.
- A public repo keeps GitHub's auto-merge, which merges as soon as the required checks pass.

## Evidence

- 2026-11-16, Renovate's source on main: `getBranchStatus` (`lib/modules/platform/github/index.ts`) returns green only when every check run is `success`, `skipped` or `neutral`, and returns red for a `failure`. `processBranch` (`lib/workers/repository/update/branch/index.ts`) skips the merge in a run that pushed a new commit, "since status checks aren't done yet", so a merge comes on a later run, after the workflows have started.
- 2026-11-16: no Renovate PR in hevy-app-audit or homelab-ipam had merged itself. Both extended the shared preset with `automerge` on, and `allow_auto_merge` doesn't save on a private repo ([`docs/DATA.md`](../DATA.md#github)).

## Alternatives rejected

- Keep [0039](0039-private-repos-run-the-checks-without-requiring-them.md): about fifteen PRs a week for TJ to merge by hand.
- GitHub Pro: a paid plan, to get required checks and GitHub's auto-merge on three repos.
- Set `platformAutomerge: false` in `defaults/renovate.json` for every repo: a public repo then merges only on Renovate's next run, not the moment its required checks pass, and gains nothing for it.
- One line in each private repo's file: three copies of the setting and of its reason.

## Consequences

- Nothing on GitHub stops a red merge in a private repo. Renovate refuses one, and a human merging by hand still reads the checks first.
- A check that starts late can be missed if Renovate reads the commit before the workflow reports at all. Workflows report within seconds of a push, and Renovate never merges in the run that pushed.
- A new private repo switches its `.github/renovate.json` to the private preset when it is made private.
- A PR whose newest commit carries a cancelled run never merges, since Renovate reads it as pending ([`docs/DATA.md`](../DATA.md#github)).
