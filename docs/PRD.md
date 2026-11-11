# yggdrasil PRD

Signed off by TJ, 2026-11-05. Built from the `initialize-project` interview.

## 1. Project overview

yggdrasil is the public, GPL-3.0 monorepo for TJ's GitHub and CI configuration. It has two halves:

- **Modules.** Versioned reusable workflows and composite actions. A repo calls one with a pinned `uses:` and its own inputs, instead of copying a pipeline. This closes zimmertr/ai-config#2.
- **Infrastructure.** Terraform that creates and manages TJ's repos and orgs, and their settings on GitHub, Docker Hub and Cloudflare. This closes zimmertr/ai-config#3.

The SBOM module (zimmertr/ai-config#13) comes after this project, as one more module.

## 2. Core requirements

1. **Consumers bring their own config.** A repo passes `with:` inputs to a module. yggdrasil stores no per-repo pipeline config. The only per-repo data it holds defines the repos and orgs themselves.
2. **Modules are versioned, and consumers subscribe.** One SemVer covers every module. A consumer pins the commit with the version in a comment. Dependabot (or Renovate) opens a PR for each new release, and the shared auto-merge merges patch and minor bumps; a major waits for TJ. A breaking module change carries `!` in its PR title, which makes it a major. Only a change under the module paths cuts a release, so a settings-only PR bumps nothing downstream.
3. **Settings change only through PRs.** Every PR posts its `terraform plan`. A merge to main applies it, and puts back any setting changed by hand.
4. **Import before apply.** No apply runs against a repo until its import shows no changes. No plan that weakens branch protection or a security setting is applied without TJ's okay.
5. **Safe in public.** Terraform manages settings and never a repo's existing files (it only creates a new repo from the template), so the private repo (Resume) exposes its name, description and settings, never its contents. Plans run only on PRs from yggdrasil's own branches, and no workflow uses `pull_request_target`.
6. **One bot identity.** A GitHub App, `zimmertr-yggdrasil-bot`, owned by `zimmertr` and installed on every owner yggdrasil manages, mints a short-lived token per run. There is no PAT, unless the verification in task P1 proves one is needed.
7. **Secret values stay out of Terraform** where possible.
8. **KISS.** Dependency config (`dependabot.yml`, `renovate.json`) stays in each repo. Only the auto-merge logic is shared.
9. **A breaking change carries `!`.** A PR that removes a module input, or adds a required one, carries `!` in its title. No CI check compares inputs with the last release: a release that breaks a caller fails that caller's bump PR, so it never merges itself (record 0025, 2026-11-05).
10. **Every consumer is production, and all are treated alike.** Each checks for yggdrasil releases daily and takes one once it is three days old, and patch and minor bumps merge themselves. A bad release is fixed forward with a new patch.
11. **Guardrails in Terraform itself.** The `github` stack's variables are typed, and a repo's file holds no security setting at all: the repo module turns every one on except where GitHub can't apply it, and the plan fails on any key or owner the stack doesn't know (records 0035, 0043).
12. **Nothing is destroyed by accident.** Every repo sets `archive_on_destroy`, so removing its file archives it, never deletes it, and a `removed` block stops managing one without touching it. Every other destroy shows in the PR's plan comment, which TJ reads before merging.

## 3. Core features

| Feature | What it does | Source |
|---|---|---|
| Release workflow | GitVersion, image build and push, a Trivy scan of each pushed platform, immutable GitHub release, deploy bump (`yq` sets a kustomization's `newTag`, a chart's `appVersion`, or both) | hevy-trainer-sync and Bluebird `release.yml` |
| PR workflows | PR title check; image build with hadolint, the Trivy comment and a smoke test | `pr-title.yml`, `pr.yml` |
| Weekly image scan | Rescans the released image | `image-scan.yml` |
| Dependabot auto-merge | Patch and minor updates merge themselves | `dependabot-auto-merge.yml` |
| Shared conventions | `GitVersion.yml` (SemVer and the bump patterns), the conventional PR title check that reads it, the release process, and `trivy.yaml`, read at the module's pinned ref; a caller can pass its own | today copied in each repo |
| `github` stack | One YAML file per repo (`repos/<owner>/<name>.yml`) and per org (`orgs/<name>.yml`), read by Terraform: settings, rulesets, security features, merge settings, immutable releases, org settings | ai-config#3 |
| Defaults | The `github` stack holds `initialize-project`'s standard settings as defaults, and a repo file sets only what differs, such as `archived: true` | new |
| Template repo | Terraform creates each new repo from a template, `zimmertr/yggdrasil-repo-template`, that already holds the PR Title and Lint callers and `dependabot.yml`, so its first PR runs the shared CI. `initialize-project` adds the `LICENSE`, `.gitignore` and README, which differ per repo | new |
| Guardrails | The preconditions (11) and `archive_on_destroy` (12) | new |
| GHCR | Every image and chart on `ghcr.io`, pushed with each job's own token, and deploys pin the digest (record 0052). Docker Hub in Terraform was dropped on 2026-11-07 | ai-config#3 notes |
| `cloudflare` stack | Moved whole from Kubernetes-Manifests `terraform/cloudflare`, with its state | Kubernetes-Manifests |

## 4. Core components

```
.github/workflows/      yggdrasil's own CI, and the reusable workflows (GitHub requires them here)
actions/<name>/         composite actions, if a module ever needs a shared step
defaults/               GitVersion.yml, trivy.yaml
repos/<owner>/<name>.yml  one file per managed repo
orgs/<name>.yml         one file per managed org
terraform/github/       reads repos/ and orgs/
terraform/cloudflare/
docs/
```

Managed orgs at the start (5): Bluebird-Forecast, Fellfield-Game, GPX-Search, TJs-Kubernetes-Service, Lakebagger.

Managed repos (17, all under `zimmertr`), every one of them both managed by Terraform and a consumer of the modules: yggdrasil, ai-config, bluebird, bluebird-helm, hevy-trainer-sync, Kubernetes-Manifests, TJs-Kubernetes-Service, Resume, 3D-Models, Bootstrap-Proxmox, Supermicro-X10-Fancontrol, Mountaineers-Activity-Scraper, Ender-6-Klipper-Guide, Personal-Website, zimmertr, Better-Lighter-Pack, Strava-Heatmap-String-Builder.

## 5. Flows

- **A repo uses a module.** It adds a short caller: `uses: zimmertr/yggdrasil/.github/workflows/release.yml@<sha> # v1.4.0`, plus its inputs. Its PR CI shows the result.
- **A module changes.** A PR in yggdrasil runs the release and docker-build modules through test callers, the release module in `dry-run` (it builds, and pushes, scans, tags, releases and opens nothing). The merge releases `vX.Y.Z`, and Dependabot opens a bump PR in each consumer once the release is three days old.
- **A setting changes.** Edit `repos/<owner>/<name>.yml`. The PR shows the plan, and the merge applies it.
- **A new repo.** Add `repos/<owner>/<name>.yml` and merge. Terraform creates the repo from the template as the App, in an org or under `zimmertr` (record 0024). Then `/initialize-project` seeds its files.
- **A new org.** TJ creates it in GitHub's UI (GitHub has no API for that) and installs `zimmertr-yggdrasil-bot`. Then `orgs/<name>.yml`, an import, and Terraform manages it from there. Moving repos into an org is a later project, such as Bluebird's Rebrand.

## 6. Tech stack

- GitHub Actions for the modules and for yggdrasil's own CI.
- Terraform with `integrations/github`, `cloudflare/cloudflare`, and Docker's provider.
- HCP Terraform org `Yggdrasil-Org` (the `Kubernetes-Manifests` org, renamed on 2026-11-05; `yggdrasil` was taken) for state and locks, in local execution mode. Plans and applies run in Actions.
- Maintained actions inside the modules, shell only where none fits, and no Python (records 0026, 0034).
- `terraform test` with mock providers, tflint, actionlint, and the Trivy config scan.
- GitVersion 6.8.2 and Trivy, the versions the consumers use today.
- Docker for every local command, through a `Makefile`.

## 7. Implementation plan

Detailed into tasks after sign-off. In order:

1. **P0 Foundation.** Create the repo, its CI, security and docs to the standard. TJ creates `zimmertr-yggdrasil-bot` and renames the HCP org.
2. **P1 Verify.**
   - Can an App create repos under a personal account?
   - Does Docker's provider set immutable tags?
   - Does Dependabot bump a reusable workflow's pin?
3. **P2 Modules.** Move hevy-trainer-sync's workflows and scripts across, with their tests and self-test callers. Release `v0.1.0`.
4. **P3 hevy-trainer-sync** switches to the modules. Run one normal release, and one rerun of a release that failed after the push. Rename the required checks in the same step (a job in a reusable workflow reports as `caller / callee`).
5. **P4 Bluebird** switches, keeping its arm64 build, fill image, chart bump, canary and every guard its `docs/CICD.md` records.
6. **P5 Every other repo.** Kubernetes-Manifests, TJs-Kubernetes-Service, bluebird-helm and the rest each take the baseline modules (PR title check, actionlint, Dependabot with auto-merge), plus the release, image or chart modules wherever the repo ships something. One PR per repo.
7. **P6 `github` stack.**
   - Import all 17 repos and the five orgs until the plan is empty.
   - Then turn on plan on PR and apply on merge.
8. **P7 GHCR.** Images and charts move from Docker Hub (#9).
9. **P8 `cloudflare` stack.**
   - Move the stack from Kubernetes-Manifests.
   - Point its `cloud` block at `Yggdrasil-Org`, where its workspace already is after the rename.
   - The plan must come back empty before anything else changes.
10. **P9 ai-config.** `initialize-project` tells new repos to call yggdrasil. ai-config#2 and #3 close.

Filed separately on yggdrasil: an audit of every secret across GitHub, Docker Hub and Cloudflare. That covers replacing `AUTO_MERGE_PAT` and `GH_PAT` with `zimmertr-yggdrasil-bot`. SBOM (ai-config#13) follows this project.

## 8. Interview choices

| Choice | Answer | Switches on |
|---|---|---|
| Users | Other repos' CI, and TJ through PRs | Module inputs documented per module; no UI, no API |
| Internet-facing | No | Nothing from `service.md` |
| Services | One repo | Monolith layout |
| Account | Personal (`zimmertr`), plus TJ's five existing orgs | No repo moves between owners in this project |
| Runs on | GitHub Actions; Terraform against four providers | Terraform for every resource; HCP state |
| Long-running service | No | No chart, no Rollouts |
| Database | No | None |
| Container image | No | No image pipeline for yggdrasil itself |
| License | GPL-3.0 | `LICENSE` |
| Visibility | Public | GitHub's free security features |
| Upstreams | GitHub, Docker Hub, Cloudflare, HCP Terraform | `docs/` lists each provider's limits and terms |
| Terraform runs | Plan on PR, apply on merge | Plan comment, apply job |
| Credential | GitHub App `zimmertr-yggdrasil-bot` | App id and key as yggdrasil secrets; no PAT |
| Managed repos and orgs | The 17 repos and 5 orgs above (the two strava-heatmap-proxy forks were deleted on 2026-11-05; Email-Infrastructure, Lakebagger/Backend and Lakebagger/Frontend, which held no code, on 2026-11-06) | One YAML file each |
| Consumers in this project | All 17 repos: the baseline modules everywhere, plus what each repo ships; future repos through the template | P3 to P5, P9 |
| Dependency config | Stays per repo | Only auto-merge is shared |

## Settled at sign-off

1. One SemVer for all modules, released only when module paths change. Consumers subscribe through Dependabot or Renovate, and non-breaking bumps merge themselves.
2. The versioning, conventional-commit and release conventions ship from yggdrasil, and a caller can override them.
3. Workflows (P2 to P5) come before Terraform (P6 to P8): each module is proven on hevy-trainer-sync before anything else depends on it.
4. The HCP org is `Yggdrasil-Org`. Kubernetes-Manifests#1888 points the Cloudflare stack at it.
5. Added after sign-off, 2026-11-05: requirements 9 to 12, profiles, the template repo, the guardrails and the release module's `dry-run` input. A separate sandbox repo was considered and dropped as more than this needs. This project builds on GitHub's free features. That is where it starts, not a limit: self-hosted runners, other platforms and paid services stay open when they become relevant. Not in this project, and open for later: a fleet report, OpenSSF Scorecard, org-level required workflows, delivery metrics, self-hosted runners, a developer portal.
6. Settled 2026-11-05: every repo is production, so there are no rollout rings; consumers check daily. Profiles start as `default` and `archived`. ArtifactHub is documented, not managed (dropped 2026-11-06, record 0040). One issue per phase. PR plans keep the App's admin-capable token for now; a `security` issue tracks a read-only plan App. All 18 repos adopt the baseline modules plus what fits.
7. Settled 2026-11-05: the App is `zimmertr-yggdrasil-bot` (App ID 5636772), installed on `zimmertr` and the five orgs. yggdrasil's own auto-merge uses it from the start, so yggdrasil has no `AUTO_MERGE_PAT`. The five orgs are managed in this epic; Lakebagger keeps its org with no repos, since its two were deleted on 2026-11-06.
8. Settled 2026-11-06, after the #4 audit: Terraform's own typed variables, preconditions and `archive_on_destroy` replace the JSON Schema, the profile files and the `destroy-approved` label (record 0035). A decision record is written only for a decision that shapes the system (record 0036).
