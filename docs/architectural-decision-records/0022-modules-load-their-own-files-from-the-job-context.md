# 0022. A module loads its own files by checking out `job.workflow_repository` at `job.workflow_sha`

- Status: Accepted
- Date: 2026-11-05
- Decider: TJ, in #3's plan, 2026-11-05: "try the `job.workflow_sha` context and the OIDC `job_workflow_sha` claim before any duplicated ref input". The first one tried worked.
- Issues and PRs: #3, #4
- Cited in code as: none yet; the first module that loads its own files, in #4, cites it
- Guide: [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md#how-a-repo-uses-a-module)

## Context

A module needs its own composite actions, scripts and `defaults/` at the commit the caller pinned. Inside a reusable workflow a `./` path resolves in the caller's checkout, `github.workflow_sha` names the caller's commit, and `sha_pinning_required` rules out pointing at a tag. The fallback was an input repeating the ref, which can drift from the pin.

## Decision

A module job that needs its own files checks itself out first:

```yaml
- uses: actions/checkout@<sha> # vX.Y.Z
  with:
    repository: ${{ job.workflow_repository }}
    ref: ${{ job.workflow_sha }}
    path: <a folder of its own>
    persist-credentials: false
```

It then runs its actions as `uses: ./<that folder>/actions/<name>` and reads its defaults from that folder. No module takes a ref input.

## Evidence

- 2026-11-05: in the #3 probe, a caller pinned the module at v0.1.0's SHA. Inside the module's job, `job.workflow_repository` and `job.workflow_sha` named the module's repo and that SHA, while `github.workflow_sha` and `github.sha` named the caller's commit. The checkout above loaded the module's v0.1.0 file, and its composite action ran from the checkout. After Dependabot bumped the pin to v0.2.0, the same steps loaded v0.2.0's file, in a run Dependabot started.
- 2026-11-05: the OIDC token's `job_workflow_sha` claim held the same SHA. [`docs/DATA.md`](../DATA.md#github) has the rest of the probe's findings.

## Alternatives rejected

- The OIDC `job_workflow_sha` claim: the same answer, but every caller would grant `id-token: write` to a job that has no other use for it.
- A ref input the caller repeats beside the pin: Dependabot and Renovate update the pin, not the input, so the two drift.

## Consequences

The checkout costs a few seconds per job that needs it. The module repo must stay public, or the caller's token can't fetch it.
