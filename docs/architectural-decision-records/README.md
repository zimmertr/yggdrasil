# Architectural decision records

One file for each design decision: what was decided, when, who decided, and the evidence that settled it. A record sits beside the `CLAUDE.md` rule that states the decision today and does not replace it. The guide tells a session what to do. The record keeps why, and since when.

## Write a record

- Copy [`0000-template.md`](0000-template.md) to `NNNN-slug.md` with the next free number. Numbers have four digits and are never reused. The slug is the decision in a few lowercase words joined by hyphens.
- The title is the decision, as one sentence.
- Take the date and the decider from the conversation or issue that settled it, quoting the decider where the words exist. When nothing records them, use the merge date and the author of the PR that shipped it, and say that git is the source.
- Give every observation the date it was made.
- `Cited in code as` lists the issue and PR numbers that source comments cite for the decision, so a search for `#20` finds the record and the code together.
- Link the record from its `CLAUDE.md` rule as ` Record: [NNNN](docs/architectural-decision-records/NNNN-slug.md)`, right after the sentence that states the decision.
- A decision ships in the same PR as its record. A PR that makes a decision without one is not done.

## Cite a record

A record is evidence, not authority. Cite it for its measurements and its reasons, never as a rule that forbids a change. When today's facts call for a different answer, the new judgement is a superseding record. TJ, 2026-10-21: "We only make decisions based on technical problems and UX. Not old ADRs."

## Supersede a record

A new record that reverses an old one says `Supersedes NNNN` in its status line. The old record changes its status line to `Superseded by NNNN` and nothing else. The `CLAUDE.md` link moves to the new record in the same PR.

## Index

| Record | Decision | Date | Status |
|---|---|---|---|
| [0001](0001-one-public-gpl-3-monorepo.md) | yggdrasil is one public GPL-3.0 repo for the shared CI modules and the Terraform that manages TJ's repos and orgs | 2026-11-05 | Accepted |
| [0002](0002-callers-bring-their-own-config.md) | Each caller passes its own configuration to a module as inputs | 2026-11-05 | Accepted |
| [0003](0003-dependency-config-stays-per-repo.md) | Dependency config stays in each repo, and only the auto-merge is shared | 2026-11-05 | Accepted |
| [0004](0004-one-version-for-every-module.md) | Every module shares one SemVer, released only when a module path changes, and callers pin the commit | 2026-11-05 | Accepted, except the breaking-change check (0025) |
| [0005](0005-every-repo-is-production.md) | Every consumer is production: each takes a release the day it ships, and patch and minor bumps merge themselves | 2026-11-05 | Superseded by 0023 |
| [0006](0006-shared-conventions-ship-as-defaults.md) | The versioning, PR title and scan conventions ship from yggdrasil as defaults a caller can override | 2026-11-05 | Accepted |
| [0007](0007-one-bot-identity.md) | Automation writes as the GitHub App zimmertr-yggdrasil-bot, with a token minted per run, and yggdrasil has no PAT | 2026-11-05 | Accepted |
| [0008](0008-terraform-plan-on-pr-apply-on-merge.md) | Terraform plans on every PR and applies on merge, with state in HCP Terraform org Yggdrasil-Org | 2026-11-05 | Accepted |
| [0009](0009-providers-in-scope.md) | Terraform manages GitHub, Docker Hub and Cloudflare, and ArtifactHub is documented, not managed | 2026-11-05 | Accepted |
| [0010](0010-safe-in-public.md) | Terraform manages settings, never a repo's files, and plans run only on yggdrasil's own branches | 2026-11-05 | Accepted |
| [0011](0011-guardrails-as-code.md) | CI refuses breaking changes without `!`, settings that weaken security, and destroys without a label | 2026-11-05 | Accepted, except the breaking-change check (0025) |
| [0012](0012-one-file-per-repo-and-org.md) | Each managed repo and org is one YAML file that names a profile, and new repos start from a template | 2026-11-05 | Accepted |
| [0013](0013-workflows-before-terraform.md) | The modules ship and are proven on hevy-trainer-sync before any Terraform, with one issue per phase | 2026-11-05 | Accepted |
| [0014](0014-foundation-by-hand-then-imported.md) | yggdrasil's own settings are set by API now and imported into Terraform in #8 | 2026-11-05 | Accepted |
| [0015](0015-skills-live-in-ai-config.md) | Shared skills live only in zimmertr/ai-config, and a repo-specific skill lives only in its repo | 2026-11-05 | Accepted |
| [0016](0016-pr-plans-keep-the-admin-token-for-now.md) | PR plans run with the App's full token for now | 2026-11-05 | Accepted |
| [0017](0017-docs-and-records.md) | Every change updates its docs page in the same PR, and every decision gets a record here | 2026-11-05 | Accepted |
| [0018](0018-checks-run-through-make-in-pinned-containers.md) | Every check runs through a make target in a container pinned by digest, the same way locally and in CI | 2026-11-05 | Accepted |
| [0019](0019-community-tools-hold-workflows-and-docs.md) | zizmor, lychee and a grep hold every workflow and doc to the repo's rules, instead of a custom check | 2026-11-05 | Accepted |
| [0020](0020-pr-titles-checked-by-a-community-action.md) | PR titles are checked by action-semantic-pull-request, against the same types GitVersion reads | 2026-11-05 | Accepted |
| [0021](0021-dependabot-with-app-auto-merge.md) | Dependabot updates actions and tool images weekly, and its patch and minor updates merge themselves as the App | 2026-11-05 | Accepted |
| [0022](0022-modules-load-their-own-files-from-the-job-context.md) | A module loads its own files by checking out `job.workflow_repository` at `job.workflow_sha` | 2026-11-05 | Accepted |
| [0023](0023-releases-bake-three-days.md) | Every consumer is production: each takes a release once it is three days old, and patch and minor bumps merge themselves | 2026-11-05 | Accepted. Supersedes 0005 |
| [0024](0024-terraform-providers-and-new-repos.md) | Terraform creates each new repo from the template, protects it with a ruleset, and fills the GitHub provider's gaps with Mastercard/restapi | 2026-11-05 | Accepted |
| [0025](0025-no-breaking-change-check.md) | No breaking-change check: each caller's own CI catches a breaking release | 2026-11-05 | Accepted |
| [0026](0026-modules-carry-only-what-callers-use.md) | The modules carry only what hevy-trainer-sync and Bluebird use today, in shell, `jq` and `yq`, with no Python | 2026-11-05 | Accepted |
