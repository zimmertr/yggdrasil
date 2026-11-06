# 0011. CI refuses breaking changes without `!`, settings that weaken security, and destroys without a label

- Status: Accepted, except the breaking-change check, which 0025 drops
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on the design review's proposals: "I agree with 1-6, lets incorporate them." On a separate sandbox repo: "If this is over engineering, we can skip it… Okay, skip it."
- Issues and PRs: #4, #8
- Cited in code as: none
- Guide: [`docs/PRD.md`](../PRD.md), requirements 4, 9, 11 and 12

## Context

One release reaches every repo on the same day, three days after it ships (0023), and one apply can change every repo's settings. A mistake in either spreads to all twenty repos at once.

## Decision

- **Breaking-change check**: every PR compares each module's `workflow_call` inputs and outputs with the last release, and fails a breaking change whose title lacks `!` (0004).
- **Release `dry-run`**: the release module takes a `dry-run` input that builds and scans but pushes, tags and releases nothing, so yggdrasil's CI can run it on every PR.
- **Import before apply**: no apply runs against a repo until its import plans with no changes.
- **Schema**: a JSON Schema validates every `repos/*.yml`, `orgs/*.yml` and profile, and refuses a file that turns off branch protection or a security feature. No plan that weakens either is applied without TJ's okay.
- **Destroy gate**: a plan that destroys a resource fails unless the PR carries the `destroy-approved` label. Removing a repo from Terraform archives it (`archive_on_destroy`), never deletes it.

## Evidence

No dated measurement.

## Alternatives rejected

- A separate `yggdrasil-sandbox` repo to try releases on first: TJ agreed to it, then dropped it as more than this needs. The `dry-run` input and the test callers cover the same risk.

## Consequences

Each guard is a CI check, so it holds only once it is a required check in branch protection. A real destroy needs TJ to add the label, on purpose.
