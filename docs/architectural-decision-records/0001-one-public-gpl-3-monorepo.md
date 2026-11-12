# 0001. yggdrasil is one public GPL-3.0 repo for the shared CI modules and the Terraform that manages TJ's repos and orgs

- Status: Accepted. Superseded in part by 0057
- Date: 2026-11-05
- Decider: TJ, 2026-11-05: "Make it public. I want a clever name… I think I also want this to manage creating and managing other repos too for ai-config#3… License: GPL 3." Then "Lets proceed with yggdrasil", and "I do want this to be simple in the end. Just fully featured, standardized, and centralized. A place to manage github."
- Issues and PRs: #1, zimmertr/ai-config#2, zimmertr/ai-config#3
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), the opening paragraph

## Context

TJ's repos each carry their own copy of the same pipeline (release, PR checks, image scan, Dependabot auto-merge), and the copies drift. zimmertr/ai-config#2 asked for shared, versioned workflows, and zimmertr/ai-config#3 asked for repo settings as code. Both needed a home.

## Decision

One public repo, `zimmertr/yggdrasil`, under GPL-3.0, holds both the reusable workflows and composite actions, and the Terraform that manages TJ's repos and orgs on GitHub, Docker Hub and Cloudflare. The SBOM work (zimmertr/ai-config#13) follows as one more module.

## Evidence

- 2026-11-05: hevy-trainer-sync and Bluebird each keep their own `release.yml`, `pr-title.yml` and `dependabot-auto-merge.yml`, and the auto-merge rule had already drifted between them (hevy-trainer-sync record 0037).

## Alternatives rejected

- Workflows in zimmertr/ai-config: a change to Claude Code config would cut a module release, and ai-config's links into `~/.claude` mean every checkout affects local sessions.
- Two repos, one for modules and one for Terraform: TJ wanted one place to manage GitHub.
- A private repo: consumers in public repos can't call a private repo's reusable workflows.

## Consequences

Everything in the repo is public, so no secret, id or private repo's contents may appear in it (0010). One repo means one version must cover the modules, and only module paths may cut a release (0004).
