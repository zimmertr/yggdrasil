# 0049. The shared issue templates and security policy are defaults, and a repo may keep its own to override them

- Status: Accepted. Supersedes 0041 and 0046 in part: a repo may keep its own copy
- Date: 2026-11-07
- Decider: TJ, 2026-11-07, in #8 step 6.17: "Yggdrasil should be shipping defaults to .github repos for each account/org. Then repos should be able to override those with their own repo configs. For example, Bluebird. So we should not be deleting what is in place for Bluebird or TKS. Other repos are open game"
- Issues and PRs: #8
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "One source for the community health files"

## Context

[0041](0041-one-source-for-community-health-files.md) said no repo keeps a copy, and [0046](0046-github-repos-take-the-shared-files-from-the-bot.md) planned one PR in each repo with its own files to delete them. On 2026-11-07, before those PRs, none of the six repos' copies matched the shared ones. Each was tailored: what to paste into a bug report, the repo's area labels, and the security policy's scope.

## Decision

- The shared files are defaults. A repo may keep its own `.github/ISSUE_TEMPLATE/` or `SECURITY.md`, and GitHub uses it there instead.
- Bluebird and TJs-Kubernetes-Service keep theirs.
- Kubernetes-Manifests, bluebird-helm, hevy-trainer-sync and yggdrasil delete theirs and use the shared ones.

## Evidence

- 2026-11-07: every one of the 24 files differed from its shared copy. Bluebird's `SECURITY.md` scopes in bluebirdforecast.com and scopes out the free APIs it calls; its `config.yml` turns blank issues on and links Discussions. TJs-Kubernetes-Service's `SECURITY.md` points to its own `docs/SECURITY_GUIDE.md`.

## Alternatives rejected

- Delete every copy, as 0041 planned: Bluebird and TJs-Kubernetes-Service would lose what their own files say.

## Consequences

- A repo's own templates hide every shared template, so an override is the whole folder. `SECURITY.md` overrides on its own.
- An override doesn't follow changes to `community-health-files/`. Its repo keeps it up to date.
