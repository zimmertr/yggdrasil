# 0041. The issue templates and security policy live once, in yggdrasil, and Terraform writes them into each owner's `.github` repo

- Status: Accepted. Supersedes 0038 and 0010 in part
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, in #7: "Why are we redundantly defining all of the issue templates? Can't we just define them in yggdrasil and import them into these repos somehow to stay DRY?", then choosing Terraform over hand-made copies, with "a disclaimer at the top indicating they should not be manually edited, but instead managed via the source in yggdrasil via terraform"
- Issues and PRs: #7, #8
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "One source for the community health files"

## Context

Record 0038 gave every repo in #7 its own `SECURITY.md` and `.github/ISSUE_TEMPLATE/`. By 2026-11-06 that was a dozen near-identical copies, and every new repo from `initialize-project` would add one more. GitHub serves default community health files from a public repo named `.github` to every repo of the same owner that has no file of its own. TJ's repos sit under six owners: the zimmertr account and five organizations, each of which needs its own `.github` repo.

## Decision

- `community-health-files/` in yggdrasil holds the one copy of the issue templates (`ISSUE_TEMPLATE/`, with `config.yml`) and `SECURITY.md`.
- Terraform (#8) writes them into the `.github` repo of the zimmertr account and of each organization it manages (Bluebird-Forecast, Fellfield-Game, GPX-Search, TJs-Kubernetes-Service and Lakebagger): the templates at `.github/ISSUE_TEMPLATE/`, `SECURITY.md` at the root. Those repos hold nothing else.
- Every file starts with a comment that says it is managed by Terraform and names its source. In an issue template the comment follows the front matter, which GitHub needs first.
- Repos keep no copies. #7's PRs drop theirs; the repos that already had them (Kubernetes-Manifests, TJs-Kubernetes-Service, bluebird-helm, hevy-trainer-sync, Bluebird and yggdrasil) delete them, one PR each, right after #8's apply writes the defaults.
- `LICENSE`, `CLAUDE.md`, `CONTRIBUTING.md` and `docs/` stay in each repo: GitHub has no default license, Claude Code reads `CLAUDE.md` from the repo, and the other two hold what is particular to a repo.
- For files, this supersedes 0010, which kept Terraform to settings so that no private repo's contents appear here. The `.github` repos are public and hold only these shared files, so that reason still holds. It also supersedes 0038's per-repo `SECURITY.md` and issue templates.

## Evidence

- 2026-11-06, GitHub's "Creating a default community health file": "Default files will be used for any repository owned by the account that does not contain its own file of that type", "regardless of the destination repository's visibility". The `.github` repo "must be public". Issue templates and their `config.yml` go in its `.github/ISSUE_TEMPLATE`, and a repo with valid templates of its own uses "none of the contents of the default" folder. "You cannot create a default license file."
- 2026-11-06, #7's twelve PRs: each carried its own `SECURITY.md` and two or three issue templates, differing only in the repo name, a few words, and the area labels.

## Alternatives rejected

- A copy in each repo (record 0038): the copies drift, and each change is a dozen PRs.
- A `.github` repo per owner, edited by hand: six copies to keep in step.
- Only `zimmertr/.github`, by hand: the organizations' repos would keep their own copies.
- A file-sync Action pushing copies into every repo: the copies would still sit in each repo's history, and it adds a workflow and a token for what GitHub does natively.

## Consequences

Until #8 writes the `.github` repos, the repos from #7 have no issue templates or `SECURITY.md`, as before #7. Area labels move out of the templates; each repo's `CLAUDE.md` Issues section lists its own. `SECURITY.md` can't link to one repo's advisory form, so it sends reporters to the repository's Security tab. Private vulnerability reporting stays a per-repo setting.
