# 0058. A repo that needs its own issue form keeps copies of the shared templates beside it

- Status: Accepted. Supersedes 0049 in part: a repo may keep its own issue templates
- Date: 2026-11-12
- Decider: TJ, 2026-11-12, planning zimmertr/hevy-garmin-sync#31: "Yggdrasil should ship the defaults to every repo. But we should be able to add more where necessary?", then "Sure" to the repo holding copies of the shared templates beside its own form.
- Issues and PRs: zimmertr/hevy-garmin-sync#31
- Cited in code as: none
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "One source for the community health files"

## Context

[0049](0049-shared-templates-and-own-security-policy.md) said no repo keeps its own issue templates. hevy-garmin-sync's status page gets a "Report this match" link for an exercise the app matched by guess, and the link has to open a form with both exercises filled in. The shared templates have no such form, and the form only makes sense in that repo.

GitHub serves a repo either its own `.github/ISSUE_TEMPLATE/` folder or the owner's shared one, never both. A repo that adds one form loses the shared bug and proposal templates and the config that turns blank issues off, unless it keeps copies of them.

## Decision

- A repo that needs an issue form the shared templates can't hold keeps its own `.github/ISSUE_TEMPLATE/` folder: copies of every file in `community-health-files/ISSUE_TEMPLATE/`, plus its own forms.
- Each copy says where its source is. The repo updates its copies by hand when the shared ones change.
- Only hevy-garmin-sync does, for `exercise-match.yml`.

## Alternatives rejected

- Terraform writes the shared templates and the repo's own into the repo: Terraform writes no repo's files but the `.github` repos' ([0010](0010-safe-in-public.md), [0041](0041-one-source-for-community-health-files.md)), and every other repo's main has no bypass for the bot. Worth building only if several repos want their own forms.
- Put the form in the shared templates: every repo's chooser would offer a form about Garmin exercises.
- A link with no template: the shared config turns blank issues off, so the link's title and body may never reach the form.

## Consequences

- hevy-garmin-sync's copies don't follow a change to `community-health-files/ISSUE_TEMPLATE/`. Whoever changes a shared template updates the copies in each repo this record lists, in a PR there.
