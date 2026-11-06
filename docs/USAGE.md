# Usage

What TJ sees from yggdrasil, and what to do when it breaks. Each part that is not built yet names the issue that turns it on.

## In a consuming repo

- **A bump PR from Dependabot or Renovate** three days after a yggdrasil release ships (#5 to #7). Patch and minor bumps merge themselves once the repo's checks pass; a major waits for TJ. Record: [0023](architectural-decision-records/0023-releases-bake-three-days.md)
- **The module's checks** on every PR, named `caller / callee`.

## In yggdrasil

- **A Dependabot PR** for an action or a tool image, weekly. Patch and minor updates merge themselves once the checks pass, armed by `zimmertr-yggdrasil-bot`, which comments on the PR to say so.
- **A plan comment** on every PR that touches `repos/`, `orgs/`, `profiles/` or `terraform/` (#8), and a weekly drift plan.

## When it breaks

- **A release breaks a consumer.** Fix forward: ship the fix as the next patch, and every consumer takes it the next day. A broken bump PR that has not merged can wait for the fix and be closed.
- **A bump PR that edits `.github/workflows` won't merge itself** in a repo still on `AUTO_MERGE_PAT`. That token has no Workflows permission, so TJ merges it until #12 moves the repo to the App.
- **A plan shows changes nobody made.** Something changed a setting outside Terraform. Read the drift plan, and either put the setting back by applying, or record the new value in the repo's YAML.
- **A plan wants to destroy something.** It fails unless the PR carries the `destroy-approved` label. Removing a repo's file archives the repo; it never deletes it. Record: [0011](architectural-decision-records/0011-guardrails-as-code.md)
