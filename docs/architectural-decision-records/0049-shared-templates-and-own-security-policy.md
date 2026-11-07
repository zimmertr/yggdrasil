# 0049. Every repo uses the shared issue templates, and a repo may keep its own `SECURITY.md`

- Status: Accepted. Supersedes 0041 and 0046 in part: a repo may keep its own `SECURITY.md`
- Date: 2026-11-07
- Decider: TJ, 2026-11-07, in #8 step 6.17: first "Yggdrasil should be shipping defaults to .github repos for each account/org. Then repos should be able to override those with their own repo configs", then "Yes" to aligning every repo's templates and keeping only Bluebird's `SECURITY.md`.
- Issues and PRs: #8, #56
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "One source for the community health files"

## Context

[0041](0041-one-source-for-community-health-files.md) said no repo keeps a copy, and [0046](0046-github-repos-take-the-shared-files-from-the-bot.md) planned one PR in each repo with its own files to delete them. On 2026-11-07, before those PRs, none of the six repos' copies matched the shared ones. Each was tailored: what to paste into a bug report, the repo's area labels, and the security policy's scope.

## Decision

- No repo keeps its own issue templates. Each repo's `CLAUDE.md` already lists its area labels, which were most of the templates' differences.
- A repo may keep its own `SECURITY.md` when its scope differs from the shared one in a way a reporter needs to know. Only Bluebird does: it is the one live public site.
- The six repos' PRs delete their templates, and every `SECURITY.md` but Bluebird's.

## Evidence

- 2026-11-07: every one of the 24 files differed from its shared copy. Bluebird's `SECURITY.md` scopes in bluebirdforecast.com and scopes out the free APIs it calls, and findings that only show those APIs can be rate-limited. TJs-Kubernetes-Service's differed only by a link to its `docs/SECURITY_GUIDE.md`, which its README already links.

## Alternatives rejected

- Delete every copy, as 0041 planned: Bluebird's reporters would lose what is out of scope for a live site.
- Let any repo keep any file: each override drifts from `community-health-files/`, and the templates' differences didn't need one.

## Consequences

- GitHub uses a repo's own `SECURITY.md` in place of the shared one, file by file, so Bluebird keeps the shared templates.
- Bluebird's `SECURITY.md` doesn't follow changes to `community-health-files/`. It names Docker Hub, so zimmertr/bluebird#111 updates it.
