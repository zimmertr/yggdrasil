# Usage

What TJ sees from yggdrasil, and what to do when it breaks. Each part that is not built yet names the issue that turns it on.

## In a consuming repo

- **A bump PR from Renovate** soon after a yggdrasil release ships. Patch and minor bumps merge themselves once the repo's checks pass; a major waits for TJ. Every other update waits seven days first, unless its registry gives no publish date. Record: [0056](architectural-decision-records/0056-one-renovate-preset-for-every-repo.md)
- **The module's checks** on every PR, named `caller / callee`.
- **Versions skip when merges land close together.** Releases run one at a time, and GitHub keeps only the newest waiting run, so a burst of merges releases once, at the last one: 0.1.0 can go to 0.1.6 with no release between. Nothing is lost, because GitVersion counts every merge since the last tag. A release run that main has moved past says "Releases nothing: main has moved past this commit" in its `Version` job, and pushes nothing. Record: [0053](architectural-decision-records/0053-release-only-from-mains-newest-commit.md)
- **In a private repo** (Resume), the same checks, but none is required and nothing merges itself: read the checks, then merge Renovate's PRs by hand. Record: [0039](architectural-decision-records/0039-private-repos-run-the-checks-without-requiring-them.md)

## In yggdrasil

- **A Renovate PR** for an action, a tool image or a Terraform provider. Everything below a major merges itself once the checks pass, except a provider update, which waits for TJ. Renovate's "Dependency Dashboard" issue lists what is waiting out its seven days.
- **A "Configure Renovate" PR in a repo yggdrasil doesn't manage.** The Renovate app is installed on every repo of the account, so a new repo needs no extra step, and Renovate opens that PR wherever it finds no config. Close it without merging: Renovate then leaves the repo alone. In a managed repo Renovate closes it itself once `.github/renovate.json` is on main.
- **A plan comment** on every PR that touches `repos/`, `orgs/` or `terraform/` (#8). When the PR merges, `Apply github` (or `Apply cloudflare`, for `terraform/cloudflare/`) applies that plan and adds the result to the same comment.

- **A new repo.** One PR adds `repos/<owner>/<name>.yml` with its `description` and the template's four checks in `required_checks` (`PR Title / PR Title`, `Lint / actionlint`, `Lint / zizmor`, `Lint / semgrep`). The merge creates the repo from `zimmertr/yggdrasil-repo-template`, with every setting and ruleset. Then run `/initialize-project` in it for its license, README and the rest (record 0024).

- **A new org.** TJ creates it in GitHub's UI, since GitHub has no API for that, and installs `zimmertr-yggdrasil-bot` on it. Then one PR adds it to `local.owners`, a provider in `providers.tf`, a token step in `terraform-github.yml`, a repo module block in `main.tf` and an org module block in `orgs.tf`, `orgs/<name>.yml`, and an import of its settings by org id in `imports.tf` (record 0051).

## When it breaks

- **A release breaks a consumer.** Fix forward: ship the fix as the next patch, and every consumer takes it the next day. A broken bump PR that has not merged can wait for the fix and be closed.
- **A bump PR that edits `.github/workflows` won't merge itself** in a repo still on `AUTO_MERGE_PAT`. That token has no Workflows permission, so TJ merges it until #12 moves the repo to the App.
- **A plan shows changes nobody made.** Something changed a setting outside Terraform. Merging the PR puts it back; to keep the new value instead, record it in the repo's or org's YAML in the same PR.
- **A plan wants to destroy something.** Read it in the PR's plan comment before merging. Removing a repo's file archives the repo; it never deletes it. To delete it, wait until the apply has archived it: a repo deleted while still in state fails every plan with a 404, until `terraform state rm 'module.<owner>["<name>"]'` takes it out. To stop managing a repo without archiving it, use a `removed` block with `destroy = false`. Record: [0035](architectural-decision-records/0035-terraform-guards-itself.md)
- **An apply refuses**, and the `Apply github` job fails without applying. Main's plan no longer matches the one in the merged PR's comment, usually because another Terraform PR merged first, so nothing was applied. Open a new PR that touches the stack (a one-line change is enough), read its plan, which shows everything still waiting, and merge it. Record: [0045](architectural-decision-records/0045-merges-apply-through-dflook.md)
- **An import's or a removal's apply refuses.** It always does: the only differences in its log are `etag` lines, a value GitHub changes for every token. Check that nothing else differs, then in the Actions tab open `terraform-github`, choose **Run workflow** on `main`, and it applies main's plan. Record: [0048](architectural-decision-records/0048-imports-apply-by-hand.md) A plan too big for the PR comment is cut off there, so compare against the full plan in the PR's run log ([DATA.md](DATA.md#github)).
- **After an import, a repo has both classic protection and rulesets.** Once the apply succeeds, delete the classic protection with `gh api -X DELETE repos/<owner>/<repo>/branches/main/protection`, then check `GET /repos/<owner>/<repo>/rules/branches/main` still lists the required checks (record 0050).
- **A plan fails on a precondition.** A repo file uses a key the stack doesn't know, sits in a folder for an owner it doesn't manage, or is a public repo with no `required_checks`. The message names which. Fix the file. Security settings aren't in repo files at all: changing one means changing `terraform/modules/repo/`, in a PR that says why (record 0043).
