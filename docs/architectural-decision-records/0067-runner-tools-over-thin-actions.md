# 0067. A module uses the runner's own git, gh, docker and curl where a few lines do an upstream action's job

- Status: Accepted. Supersedes 0020, and 0006, 0027, 0033, 0034, 0054, 0059, 0062 and 0066 in part
- Date: 2026-11-21
- Decider: TJ, 2026-11-21: "Do some only really exist as dependencies because I was so stern about not writing any scripts in CI? Can any be entirely replaced with just a handful of shell, python, etc commands?", then "Yes, but you need to makes sure the shell code is clean and optomizes for human readability and isn't full of ai code comment spam"
- Issues and PRs: #133, #145
- Cited in code as: decision record 0067, in `actions/` and the modules that call them
- Guide: [`CLAUDE.md`](../../CLAUDE.md), "A maintained action or input before shell"

## Context

Record 0034 preferred any maintained action to a shell step. A second ranking of the CI upstreams, after #133, found that most actions in a job holding a write token or able to sign wrapped `git`, `gh`, `docker` or `curl`, which GitHub's runner already ships. Each one was an upstream running with that job's credentials, for a few lines of work.

## Decision

- A module uses the runner's own `git`, `gh`, `docker` and `curl` where a few lines do an upstream action's job. A maintained action stays where it does real work: `actions/checkout`, `actions/attest`, `docker/build-push-action`, Trivy, hadolint, helm-unittest, container-structure-test, `yq` and dflook.
- Shell used in more than one place lives once, in a composite action under `actions/`, with its script in a `.sh` file beside it. A module calls it as `uses: $/actions/<name>`, which GitHub resolves to yggdrasil at the module's own commit, with no checkout. Any other repo pins it by SHA, as it pins a module.
- What replaced what:
  - `amannn/action-semantic-pull-request` and GitVersion: `actions/pr-title` and `actions/version`, over one script, `actions/version/version.sh`, which holds the one list of types. The next version is the last `v*` tag, bumped once by the biggest bump among the commits since it that touch the release's `paths`. The first release is 0.1.0. A caller's own `GitVersion.yml` is no longer read.
  - `peter-evans/create-pull-request`: `actions/open-pr`.
  - `marocchino/sticky-pull-request-comment`: `actions/sticky-comment`, which writes and finds the same hidden marker, so it edits the comments the old action posted.
  - `azure/setup-helm`: `actions/setup-helm`, which downloads Helm and checks it against the checksum Helm publishes. The version is pinned there, once.
  - `docker/login-action`, `docker/setup-buildx-action` and `docker/setup-qemu-action`: one `docker` command each. QEMU comes from the `tonistiigi/binfmt` image the action pulled, now pinned by digest.
  - `docker/metadata-action`: the tag and the OCI labels, written into the build step's inputs.
  - Resume's `xu-cheng/latex-action` and `softprops/action-gh-release`: its own Dockerfile and `gh release`, in Resume's own PR.
- bats tests `version.sh` and `open-pr.sh` (`make bats`, the `Bats` check). `Lint / shellcheck` reads every `.sh` file.
- Renovate reads a pin in an env var under a `# renovate:` comment, through a manager in the shared preset, so the Helm version and the binfmt digest still move.

## Evidence

- 2026-11-21, the CI upstreams ranked again: the five `docker/*` actions had one maintainer for 95 to 98% of their last commits, `peter-evans/create-pull-request` and `marocchino/sticky-pull-request-comment` were personal accounts, and one person wrote 51 of GitVersion's last 52 commits. GitVersion's pin was out of Renovate's reach, and 7.0.1 was waiting.
- 2026-11-21, GitHub's ubuntu-24.04 image readme: GitHub CLI 2.104.0, Docker-Buildx 0.39.0, yq 4.54.3 and Helm 3.22.1. Helm 3 is behind the pinned 4.3.2, so Helm is still downloaded.
- 2026-11-21: zizmor's `superfluous-actions` audit flagged `peter-evans/create-pull-request` and `softprops/action-gh-release`, and `release.yml`, hevy-garmin-sync and Resume ignored it.
- 2026-11-21, `src/comment.ts` in marocchino/sticky-pull-request-comment: the body is followed by `<!-- Sticky Pull Request Comment<header> -->`, and a comment is found by that marker and by the token's login.
- 2026-11-21: none of the callers of the release module has its own `GitVersion.yml`.
- 2026-11-21, GitHub's workflow syntax reference: "`$/` always resolves against the repository of the file it appears in, not the repository that called it."

## Alternatives rejected

- Keeping the actions behind the 30-day wait (0062). The wait slows a compromise down, but the action still runs with the token.
- The runner's `yq` in place of mikefarah's action: the same author's code, at whatever version GitHub's weekly image carries instead of a pin.
- Replacing `docker/build-push-action`: its `type=gha` cache reads a runtime token GitHub passes to actions and not to `run:` steps.
- One `version` action that only checks a title when given one: an empty title would have skipped the check and passed.

## Consequences

- yggdrasil owns about 110 lines of shell and their tests.
- `open-pr` runs only in a real release's deploy job. bats covers how it branches, against a local remote with a stand-in for `gh`, and the first deploy bump after the release is its live test.
- Several merges since the last tag release once, bumped by the biggest of them. GitVersion bumped once per merge, so a burst of fixes gave 0.1.6 where it now gives 0.1.1.
- trailhead, Kubernetes-Manifests and hevy-garmin-sync call the replaced actions directly and switch in their own PRs. Until they do, those actions wait seven days, not 30.
