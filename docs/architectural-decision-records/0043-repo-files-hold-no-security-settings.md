# 0043. A repo's file holds no security setting: the repo module turns each one on, and the stack refuses any key or owner it doesn't know

- Status: Accepted. Supersedes 0035's per-feature preconditions and 0012's `repos/<name>.yml` layout. Superseded in part by 0050
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, in #8. On the guards, after the pros, cons and consequences: "LGTM". On the layout, `repos/<owner>/<name>.yml`, chosen from the options. On labels, "Leave labels out". On merging step 6.3 into 6.4, "One PR".
- Issues and PRs: #8
- Cited in code as: decision record 0043, in `terraform/github/main.tf`, `terraform/modules/repo/` and both `tests/` folders
- Guide: [`CLAUDE.md`](../../CLAUDE.md), One YAML file per repo and per org

## Context

Record 0035 planned typed inputs for every setting, with a precondition per security feature that failed the plan when a repo's file turned it off. That is one input, one precondition and one test per feature, to guard a choice no repo needs: every repo TJ manages takes the same security standard, apart from what GitHub Free can't apply to a private repo. Separately, every owner now has a `.github` repo (record 0041), so `repos/<name>.yml` would hold six files of the same name.

## Decision

- **One file per repo at `repos/<owner>/<name>.yml`.** The folder names the owner, so a file can't name the wrong one. A folder for an owner the stack doesn't manage fails the plan.
- **A file may set only what can differ between repos:** `description`, `homepage_url`, `topics`, `visibility`, `archived`, `is_template` and `required_checks`. Their defaults live once, in `terraform/github/main.tf`'s `local.defaults`, and those keys are the whole list. A file with any other key fails the plan, through a precondition on `output.repos`, because Terraform otherwise drops an object's unknown attributes without a word: `achived: true` would be ignored.
- **No security setting is an input.** The repo module turns each one on: the default-branch and `v*` tag rulesets, secret scanning and push protection, Dependabot alerts and security updates, SHA pinning, private vulnerability reporting, immutable releases and CodeQL default setup. It skips only what GitHub can't apply. A private repo on GitHub Free gets no rulesets, secret scanning, CodeQL or private vulnerability reporting (0039). An archived repo is read-only, so only the repo itself stays managed. A public repo with no `required_checks` fails the plan. Weakening any of this means changing the module, in a PR TJ reviews.
- **No labels.** `github_issue_labels` deletes every label it doesn't list, including the session labels `create-issue` adds while it works. Labels stay with `create-issue`.
- **One `github` and one `restapi` provider per owner**, each with a token the workflow mints from `zimmertr-yggdrasil-bot` for that owner, passed in as the sensitive map `github_tokens`. Terraform can't loop over providers, so each owner has its own module block. No private key or installation id is in the code.
- Steps 6.3 and 6.4 of #8 ship as one PR, because the defaults are the module's inputs and the guards sit on its resources.

## Evidence

- 2026-11-06, `terraform test` on mock providers, Terraform 1.17.1: the repo module's four runs passed (a public repo gets every setting, a private repo skips what GitHub Free can't do, an archived repo keeps only the repo, a public repo with no required checks fails), and the stack's three passed (each file reaches its own owner's module, `.github.yml` included; an unknown key fails; an unknown owner folder fails).
- 2026-11-06: Trivy flags every public `github_repository` Critical (GIT-0001), so the module suppresses that one rule, with the reason. GIT-0003 (vulnerability alerts) didn't fire on the module, so it has no suppression.

## Alternatives rejected

- Record 0035's per-feature inputs and preconditions: more code and tests, for exceptions no repo has.
- A flat `repos/<owner>--<name>.yml`: the owner would sit in a file name, where a typo makes a new owner.
- Terraform owning all labels: `create-issue` would need a yggdrasil PR for every new label.
- The shared labels only, one resource each: about ten per repo, roughly 230 of HCP Free's 500 managed resources.

## Consequences

- An import plan shows any repo whose live security settings differ from the standard. That repo is fixed first, or its import isn't imports only.
- A repo that ever needs a security feature off needs a new input in the module, in a reviewed PR.
- A setting a repo needs that isn't in `local.defaults`, such as a wiki, is added there in the PR that needs it, with its default.
