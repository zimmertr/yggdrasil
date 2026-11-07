# Architecture

yggdrasil has two halves that share one repo, one version and one bot identity:

- **Modules**: reusable workflows and composite actions. A repo calls one with a pinned `uses:` and its own inputs, instead of copying a pipeline.
- **Infrastructure**: Terraform that creates and manages TJ's repos and orgs on GitHub, Docker Hub and Cloudflare.

The full design is in [PRD.md](PRD.md). This page says what each part is, where it lives, and which issue builds it. Each part below is built by the issue it names.

## Layout

| Path | Holds | Built in |
|---|---|---|
| `.github/workflows/` | yggdrasil's own CI, and the reusable workflows (GitHub requires both here) | #2, #4 |
| `actions/<name>/` | Composite actions, if a module ever needs a shared step. None yet (record 0026) | #4 |
| `defaults/` | The shared conventions: `GitVersion.yml`, `trivy.yaml` | #4 |
| `community-health-files/` | The one copy of the issue templates and `SECURITY.md`, which Terraform writes into each owner's `.github` repo (record 0041) | #8 |
| `tests/<module>/` | What a module's test caller builds, such as `tests/docker-build/`'s empty image | #4 |
| `repos/<owner>/<name>.yml` | One file per managed repo, in its owner's folder: only what differs from the defaults, and never a security setting (record 0043) | #8 |
| `orgs/<name>.yml` | One file per managed org | #8 |
| `terraform/github/` | The stack that reads `repos/` and `orgs/`, with the defaults, one provider pair per owner, and the preconditions that refuse an unknown key or owner | #8 |
| `terraform/modules/repo/` | One repo and every setting `initialize-project` gives it, with each security feature always on where GitHub allows it | #8 |
| `terraform/dockerhub/` | Docker Hub repositories and their immutable tags | #9 |
| `terraform/cloudflare/` | The stack moved from Kubernetes-Manifests, with its state | #10 |
| `GitVersion.yml` | yggdrasil's own version and the PR title patterns that pick each bump | #2 |
| `Makefile`, `compose.yml` | Every check as a `make` target, and the pinned images each one runs in | #2 |
| `docs/` | These pages and the decision records | #2 |

## How a repo uses a module

```mermaid
flowchart LR
  subgraph consumer["A consuming repo"]
    caller["caller workflow<br/>uses: zimmertr/yggdrasil/...@sha # vX.Y.Z<br/>with: its own inputs"]
    dep["Dependabot or Renovate<br/>checks daily"]
  end
  subgraph ygg["yggdrasil"]
    mod["reusable workflow<br/>or composite action"]
    rel["release vX.Y.Z"]
  end
  caller -->|runs| mod
  rel -->|new tag| dep
  dep -->|bump PR| caller
```

- The caller passes everything repo-specific as inputs. yggdrasil keeps no per-repo pipeline config. Record: [0002](architectural-decision-records/0002-callers-bring-their-own-config.md)
- Every module shares one SemVer. A merge that changes a module path releases; a settings-only merge releases nothing. Record: [0004](architectural-decision-records/0004-one-version-for-every-module.md)
- Each consumer takes a release once it is three days old. Patch and minor bumps merge themselves; a major waits for TJ. Record: [0023](architectural-decision-records/0023-releases-bake-three-days.md)

A job inside a reusable workflow reports its check as `<caller job name> / <module job name>`, so a consumer that switches to a module renames its required checks in the same step (#5 to #7). A `./` path inside a reusable workflow resolves in the caller's checkout, not in yggdrasil's, so a module that needs its own files checks out `job.workflow_repository` at `job.workflow_sha`, the commit the caller pinned. Record: [0022](architectural-decision-records/0022-modules-load-their-own-files-from-the-job-context.md)

## How a setting changes

```mermaid
flowchart LR
  edit["edit repos/name.yml"] --> pr["PR"]
  pr --> plan["terraform plan<br/>posted on the PR<br/>preconditions refuse unknown keys and owners"]
  plan --> merge["merge to main"]
  merge --> apply["terraform apply"]
  weekly["weekly drift plan"] -.-> main["main"]
```

Terraform guards itself: a repo file can't hold a security setting, the plan refuses a key or owner the stack doesn't know, and every repo is archived, never deleted, when it leaves Terraform. Records: [0035](architectural-decision-records/0035-terraform-guards-itself.md), [0043](architectural-decision-records/0043-repo-files-hold-no-security-settings.md)

Until #8 imports them, settings are API calls TJ okays first, logged in [CICD.md](CICD.md#settings-applied-by-api). Record: [0014](architectural-decision-records/0014-foundation-by-hand-then-imported.md)

## The bot

Every write that automation makes, in yggdrasil and later in the consumers, uses a token minted per run from the GitHub App `zimmertr-yggdrasil-bot`. Its permissions and installations are in [CONFIGURATION.md](CONFIGURATION.md#the-app). Record: [0007](architectural-decision-records/0007-one-bot-identity.md)

## What is managed

Five orgs (Bluebird-Forecast, Fellfield-Game, GPX-Search, TJs-Kubernetes-Service, Lakebagger) and seventeen repos, listed in [PRD.md](PRD.md#4-core-components). Each repo is both managed by Terraform and a consumer of the modules. Record: [0012](architectural-decision-records/0012-one-file-per-repo-and-org.md)
