# Upstream providers

Each service yggdrasil talks to: what it uses there, where that provider's limits and terms are, and every quirk found, dated. This page links to each provider's own limits instead of copying the numbers, because the providers change them. Every link was checked on 2026-11-05.

## GitHub

Uses: Actions (the modules and yggdrasil's own CI), the REST and GraphQL APIs (through Terraform's `integrations/github` provider and `gh`), GitHub Apps, and Dependabot.

- Limits: [REST API rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api), [GitHub App rate limits](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/rate-limits-for-github-apps), [Actions limits](https://docs.github.com/en/actions/reference/limits).
- Terms: [GitHub Terms of Service](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service).
- Provider: [`integrations/github`](https://registry.terraform.io/providers/integrations/github/latest/docs).

Quirks:

- 2026-11-05: Dependabot's metadata reads a calendar-versioned package's year change as a major. tzdata 2025.2 to 2026.6 came through as `version-update:semver-major` (zimmertr/hevy-trainer-sync#36), so it waits for TJ even under patch-and-minor auto-merge.
- 2026-11-05: a caller can pass only stored secrets to a reusable workflow, never a token it minted in an earlier job. A caller job also can't set `environment:`, so a module that needs an environment takes its name as an input.
- 2026-07-30 ([changelog](https://github.blog/changelog/2026-07-30-reference-same-repository-actions-with-self-repository-syntax/)): `uses: $/path` is the repo's own action or reusable workflow at the running commit, with no checkout, on runner 2.336.0 or newer. zizmor 1.32.0 asks for it in place of `./`. It covers `uses:` only, so a module still checks itself out to read a file such as `defaults/GitVersion.yml` (0022). actionlint 1.7.12 rejects it and doesn't know `job.workflow_repository` or `job.workflow_sha`; `.github/actionlint.yaml` ignores those three messages.
- 2026-11-05: a PR's merge commit carries GitHub's "Merge ... into ..." message, so GitVersion run on it can't see the PR title. The release module's dry run builds the squash commit the merge will make instead, and on #28 gave v0.2.0 for a `feat` that followed #25's `feat(defaults)` with no tag yet: GitVersion counted past the `v0.1.0` seed.

Found in #3 with two throwaway repos, a module and a caller pinning it by SHA with `sha_pinning_required` on. The repos are deleted when #3 closes, so the evidence is quoted here rather than linked.

- 2026-11-05: inside a module's job, `job.workflow_repository`, `job.workflow_sha` and `job.workflow_ref` name the module's own repo and the commit the caller pinned. The `github.workflow_*` contexts name the caller's workflow instead. The OIDC token's `job_workflow_sha` claim matches `job.workflow_sha`, but needs `id-token: write`. A checkout of `job.workflow_repository` at `job.workflow_sha` loaded the module's files, and its composite action ran from that checkout. Record: [0022](architectural-decision-records/0022-modules-load-their-own-files-from-the-job-context.md)
- 2026-11-05: a module's check is named `<caller job name> / <module job name>`, for example `Plain / Probe`.
- 2026-11-05: a module job with `environment: ${{ inputs.environment }}` runs with no environment when the input is empty, and an empty `environment` claim in its OIDC token.
- 2026-11-05: with `secrets: inherit`, a module gets the caller's repo secrets, plus its environment secrets in a job that sets the environment. In a run Dependabot starts, it gets only the Dependabot secrets. Repo and environment secrets arrive empty, even in the job that sets the environment.
- 2026-11-05: a `concurrency` group in the caller, with none in the module, cancels the caller's earlier run when a second starts.
- 2026-11-05: Dependabot's `github-actions` ecosystem reads a SHA-pinned module call with its `# vX.Y.Z` comment, and rewrites both. Its dependency name is the workflow path, `<owner>/<repo>/.github/workflows/<file>.yml`, so an `ignore` rule that names only the repo matches nothing. `dependabot/fetch-metadata` reported `version-update:semver-minor` for 0.1.0 to 0.2.0 and `version-update:semver-patch` for 0.2.0 to 0.2.1.
- 2026-11-05: with no `cooldown` set, Dependabot still held a two-minute-old release back: "Days since release : 1 (cooldown days 3)". With `cooldown: default-days: 0`, the next run opened the PR at once. So a consumer without its own `cooldown` gets a yggdrasil release three days after it ships, which is what TJ chose: each consumer sets those three days explicitly (0023). yggdrasil's own updates wait seven (0021).
- 2026-11-05: Renovate 44.221.0 with `config:recommended` reads the same pin and comment. It names the dependency by repo, `<owner>/<repo>`, and called v0.2.0 to v0.2.1 `patch` and v0.2.1 to v0.3.0 `minor`, not breaking, so Kubernetes-Manifests' patch-and-minor auto-merge would take a 0.x minor. It was a dry run in a container; the probe never had the Renovate app.
- 2026-11-05: `GITHUB_TOKEN`, which never holds the Workflows permission, merged a Dependabot PR that edits `.github/workflows` (`gh pr merge --squash`, merged by `app/github-actions`). That merge started no `on: push` workflow, so a consumer merged that way never releases. The App token is still needed, to start the consumer's push workflows, not for the Workflows permission. Arming auto-merge with `--auto` was not tested.

Terraform, run in a workflow with an installation token for `zimmertr`, with `integrations/github` 6.13.0, `Mastercard/restapi` 3.0.0 and Terraform 1.16.7:

- 2026-11-05: an installation token can't create a repo under `zimmertr` with `POST /user/repos`. GitHub answered 403 "Rate Limit Exceeded" on the job's first call, twice, on two runs. A plain `github_repository` create calls that endpoint under a personal account. Generating from a template (`POST /repos/{owner}/{template}/generate`) worked with the same token, and so did a `github_repository` with a `template` block, which calls it. Record: [0024](architectural-decision-records/0024-terraform-providers-and-new-repos.md)
- 2026-11-05: every setting in `initialize-project`'s `repo.md` and `security.md` applied to an imported repo, and a second plan found nothing to change. Read back afterwards: squash only with `PR_TITLE` and `PR_BODY`, auto-merge, branch deletion, update branch, wiki and projects off, secret scanning and push protection, Dependabot alerts and security updates, `sha_pinning_required`, private vulnerability reporting, immutable releases, CodeQL default setup for `actions`, and an active ruleset on the default branch. [CONFIGURATION.md](CONFIGURATION.md#what-terraform-manages) maps each setting to its resource.
- 2026-11-05: `integrations/github` 6.13.0 has no resource for private vulnerability reporting (integrations/terraform-provider-github#2399), immutable releases (#2746) or CodeQL default setup (#1648, closed as stale). `restapi_object` manages each one. It needs `ignore_server_additions = true`, or every field GitHub returns lands in `data` and every plan shows a change. `PUT .../immutable-releases` refuses a body ("enabled" is not a permitted key), so its `data` is `{}`, and Terraform won't notice if someone turns it off by hand.
- 2026-11-05: CodeQL's default setup reports `languages: []` until its first analysis finishes, about a minute after it is configured, so a plan inside that minute shows one change.
- 2026-11-05: `github_branch_protection` names required checks by name only. `github_repository_ruleset`'s `required_check` also takes the `integration_id` of the app that must report it (15368 for GitHub Actions), which yggdrasil's own protection pins today.
- 2026-11-05: once a ruleset requires PRs on main, the App can't commit to main either: `github_repository_file` failed with "409 Repository rule violations found" until the file was created before the ruleset. The App isn't a bypass actor.
- 2026-11-05: the App's current permissions covered every call above. Org-level settings were not exercised.
- integrations/terraform-provider-github#3223, open: `sha_pinning_required = false` is silently ignored. yggdrasil only sets it to `true`.
- 2026-11-05: a fine-grained PAT binds to one owner, and the Bluebird-Forecast org caps its lifetime at 366 days (zimmertr/bluebird#311).
- GitHub has no API to create an org. TJ creates each one in the UI, and Terraform takes over from its import.

## Docker Hub

Uses: the repositories that consumers push images to, and their immutable tags (#9).

- Limits: [Docker Hub usage and limits](https://docs.docker.com/docker-hub/usage/).
- Terms: [Docker Terms of Service](https://www.docker.com/legal/docker-terms-service/).
- Provider: [`docker/docker`](https://registry.terraform.io/providers/docker/docker/latest/docs).

Quirks, found in #3 with the throwaway repo `zimmertr/yggdrasil-probe`:

- 2026-11-05: `docker/docker` 0.7.0's `docker_hub_repository` created a public repo with `immutable_tags_settings = { enabled = true, rules = [".*"] }`, and a second plan found nothing to change. Pushing `v1` again with different content was refused: "tag v1 is already assigned to an image in this repository and cannot be updated due to immutability settings".
- 2026-11-05: the provider logs in with a username and a personal access token. An older token that could log in, but whose scope was never recorded, failed with "access denied: insufficient scope". The run passed with a token TJ made for it, asked for with the Read, Write, Delete scope.

## Cloudflare

Uses: the stack that moves from Kubernetes-Manifests `terraform/cloudflare` (#10).

- Limits: [Cloudflare API rate limits](https://developers.cloudflare.com/fundamentals/api/reference/limits/).
- Terms: [Cloudflare Website and Online Services Terms](https://www.cloudflare.com/website-terms/).
- Provider: [`cloudflare/cloudflare`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs).

## HCP Terraform

Uses: state and locks for every stack, in org `Yggdrasil-Org`, in local execution mode.

- Docs: [HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs) and [workspace settings](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings).
- Pricing: [HashiCorp pricing](https://www.hashicorp.com/en/pricing).
- Terms: [HashiCorp Website Terms of Service](https://www.hashicorp.com/en/terms-of-service). It covers hashicorp.com itself (last updated March 2018), not the use of HCP Terraform, and the service agreement is not linked here yet.

Both HashiCorp pages answer scripted requests with HTTP 429, so TJ checked them in a browser on 2026-11-05.

Quirks:

- 2026-11-05: `Yggdrasil-Org` is on the Free plan, with a 500 managed-resource limit and no charge (its **Plan & billing** page, read by TJ). The limit covers the whole org, every stack together. HashiCorp's [plans overview](https://developer.hashicorp.com/terraform/cloud-docs/overview): "Free organizations are limited to 500 managed resources."
- 2026-11-05: a managed resource is a `mode = "managed"` resource in a state file HCP Terraform holds, counted from its first plan or apply. Data sources and null resources don't count. Local execution mode still counts, because the state still lives in HCP. HashiCorp's blog post "Continuing HCP Terraform's enhanced free tier experience" defines it, and [Estimate HCP Terraform cost](https://developer.hashicorp.com/terraform/cloud-docs/overview/estimate-cost) shows where to see the org's count. The legacy user-based Free plan ended on 2026-03-31.
- 2026-11-05: the pricing page lists only the paid plans (Essentials, Standard, Premium, each priced per managed resource per month), so it doesn't show the Free plan at all.

- 2026-11-05: the org name `yggdrasil` was already taken. TJ renamed the existing `Kubernetes-Manifests` org to `Yggdrasil-Org` instead, which kept the Cloudflare workspace and its state in place (Kubernetes-Manifests#1888).
