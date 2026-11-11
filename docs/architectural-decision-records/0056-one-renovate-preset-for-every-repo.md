# 0056. One Renovate preset holds the dependency rules, and every repo extends it

- Status: Accepted. Supersedes 0003 and 0021, and 0023 in part: the three-day wait
- Date: 2026-11-11
- Decider: TJ, 2026-11-11. On the wait: "Lets make sure everything has at least a 1-week cooldown then." On the tool: "I am tempted to switch everything and just define it in yggdrasil and import it into the child repos", then "I agree, lets do it." On yggdrasil's own modules: "Those can go immediately". On an image that can't be aged: "I need auto-merging as much as possible. It's too much work for one person to maintain this."
- Issues and PRs: #40
- Cited in code as: record 0056, in `defaults/renovate.json`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), Rules, "One Renovate preset"

## Context

[0003](0003-dependency-config-stays-per-repo.md) kept each repo's dependency config in the repo, and [0021](0021-dependabot-with-app-auto-merge.md) put most repos on Dependabot with an auto-merge workflow beside it. On 2026-11-11 the wait before an update was three days in twelve repos and seven in three, the `docker` entries in bluebird and hevy-garmin-sync had none, and TJs-Kubernetes-Service waited only on yggdrasil's modules. Kubernetes-Manifests and TJs-Kubernetes-Service were already on Renovate, because Dependabot can't read their files.

## Decision

- `defaults/renovate.json` is the one preset. Each repo's `.github/renovate.json` extends `github>zimmertr/yggdrasil//defaults/renovate` and adds only its own rules.
- Every update waits seven days after its release. yggdrasil's own modules don't wait.
- An update whose registry gives no publish date doesn't wait either, because nothing can age it.
- Everything below a major merges itself once the repo's required checks pass. A major waits for TJ.
- No repo keeps a `dependabot.yml` or an auto-merge workflow. The `auto-merge` module goes once its last caller does.

## Evidence

- 2026-11-11: in the last 90 days Dependabot would have opened 4 of the 138 update PRs Renovate merged in Kubernetes-Manifests (#40's comment).
- 2026-11-11: a Dependabot repo carried 17 to 118 lines of `dependabot.yml` and a 21-line auto-merge caller. A repo on the preset carries about four lines.
- 2026-11-11, Renovate's docs: a Docker image is aged only from Docker Hub's push date. GHCR, Quay and ECR give none, and since Renovate 42 the default (`minimumReleaseAgeBehaviour: timestamp-required`) holds such an update forever. Security updates skip `minimumReleaseAge`. [`docs/DATA.md`](../DATA.md#github)
- 2026-11-11: `renovate-config-validator --strict` passes the preset and yggdrasil's own file.

## Alternatives rejected

- Keep Dependabot and set seven days in each file: sixteen files to edit now and again at the next change.
- Hold an image that can't be aged for TJ's merge: more PRs for one person to merge by hand.
- Pin the preset to a yggdrasil tag: a change to the wait would then need a bump PR in every repo before it applied.

## Consequences

- A change to the preset applies to every repo on Renovate's next run, with no PR in that repo. `defaults/` is a module path, so the change also releases a patch.
- The Renovate app has write access to every repo of TJ's.
- An image from GHCR, Quay or ECR merges itself the day it ships. Pinning it by digest still stops a tag from changing under a running workload.
- A consumer takes a yggdrasil release as soon as Renovate sees it, not three days later. The test callers and the release dry run in yggdrasil's own CI stay the first guard against a bad release.
- Dependabot's security updates stay on as a repo setting, so a vulnerable dependency can get a PR from both tools. Dependabot's waits for TJ.
- A repo keeps a rule of its own where it has a reason: in yggdrasil a Terraform provider update still waits for TJ ([0042](0042-terraform-module.md)).
