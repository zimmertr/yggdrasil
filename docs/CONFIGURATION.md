# Configuration

Every setting yggdrasil depends on, and where each is set. The repo's own settings are logged in [CICD.md](CICD.md#settings-applied-by-api), and its secrets are listed there too.

## Module inputs

None yet. Each module documents its inputs here when #4 adds it: the name, whether it is required, its default, and what it changes. A caller passes all of its configuration this way. Record: [0002](architectural-decision-records/0002-callers-bring-their-own-config.md)

## Shared defaults

`defaults/GitVersion.yml` and `defaults/trivy.yaml` arrive with #4. A module reads them at its own pinned ref, and a caller can pass its own file instead. Record: [0006](architectural-decision-records/0006-shared-conventions-ship-as-defaults.md)

## The App

`zimmertr-yggdrasil-bot`, checked with `gh api apps/zimmertr-yggdrasil-bot` on 2026-11-05. Record: [0007](architectural-decision-records/0007-one-bot-identity.md)

- **App ID**: 5636772. Owned by `zimmertr`, installable on any account, no webhook.
- **Installed on**: `zimmertr` (all repositories), and the orgs Bluebird-Forecast, Fellfield-Game, GPX-Search, TJs-Kubernetes-Service and Lakebagger. TJ installs it on any new owner, because a token minted for one owner can't write to another.
- **Repository permissions**: Actions, Administration, Contents, Environments, Pull requests and Workflows (read and write); Metadata (read).
- **Organization permissions**: Administration (read and write); Members (read).

A permission change takes effect on an owner only after that owner accepts it in its installation settings. #3 confirms whether anything else is needed.

## Terraform

The stacks use HCP Terraform org `Yggdrasil-Org` for state and locks, in local execution mode: plans and applies run in Actions, not on HCP. Record: [0008](architectural-decision-records/0008-terraform-plan-on-pr-apply-on-merge.md)

`repos/<name>.yml`, `orgs/<name>.yml`, the profiles and their schemas arrive with #8, and their fields are documented here then. Record: [0012](architectural-decision-records/0012-one-file-per-repo-and-org.md)
