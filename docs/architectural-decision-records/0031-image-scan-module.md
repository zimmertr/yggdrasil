# 0031. The image-scan module takes a JSON list of images, scans each once, and converts the report to SARIF

- Status: Accepted, except the `jq` gate and `trivy convert`, which 0034 replaces with trivy-action's own inputs
- Date: 2026-11-05
- Decider: TJ, 2026-11-05, on #4 item 2.10: "LGTM, proceed."
- Issues and PRs: #4, #32
- Cited in code as: decision record 0031, in `.github/workflows/image-scan.yml`
- Guide: [`docs/CONFIGURATION.md`](../CONFIGURATION.md#image-scanyml)

## Context

hevy-trainer-sync rescans one released image every week and Bluebird two, each with its own Security tab category and failure message. Both run Trivy twice, once for SARIF and once for the JSON the gate counts.

## Decision

- One input, `images`: a JSON list of `{image, category, remedy}` that becomes the job's matrix. Every image is scanned at the caller's latest release, `linux/amd64` only, the cluster's platform.
- Trivy runs once, to JSON. `trivy convert` writes the SARIF for the Security tab, and `jq` counts the Critical and High from the same JSON.
- The `jq` count stays inline, as in docker-build: it is one expression, so a composite action would add a checkout for nothing (0026).
- No test caller: it scans an image at the caller's latest release, and yggdrasil releases no image. #5 is its first real run.

## Evidence

- 2026-11-05: Trivy 0.70.0 in a container scanned `alpine:3.20` to JSON, and `trivy convert --format sarif` wrote SARIF 2.1.0 with the same two findings.

## Alternatives rejected

- Two scans, as today: twice the time, and two reports that could disagree.
- A `platform` per image: every image runs on the amd64 cluster.

## Consequences

A caller with an arm64-only image adds a `platform` field then, as a minor.
