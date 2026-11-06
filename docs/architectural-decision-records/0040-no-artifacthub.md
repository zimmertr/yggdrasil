# 0040. TJ's Helm charts are not listed on ArtifactHub, and yggdrasil documents no ArtifactHub steps

- Status: Accepted. Supersedes 0009 in part
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, on #7 step 5.5: "Maybe we just stop using ArtifactHub?", then "Yes. Lets completely drop it and update Kubernetes Manifests, Bluebird, Bluebird-Helm, Yggdrasil, and Ai-Config as necessary."
- Issues and PRs: #7, #9, zimmertr/bluebird-helm#457
- Cited in code as: none
- Guide: [`docs/DATA.md`](../DATA.md)

## Context

[0009](0009-providers-in-scope.md) kept ArtifactHub as a documented service: yggdrasil would write down how to list a Helm chart there. bluebird-helm was the only chart listed. ArtifactHub reads a repo's metadata from the `artifacthub.io` tag in the chart's OCI repo, so changing the metadata means overwriting that tag, and TJ's Docker Hub repos keep immutable tags on purpose.

## Decision

- No chart of TJ's is listed on ArtifactHub. bluebird-helm publishes to Docker Hub only (bluebird-helm#457).
- #9 writes no ArtifactHub steps, and `initialize-project` no longer plans a listing for a new chart.
- ArtifactHub is no longer one of yggdrasil's services.

## Evidence

- 2026-11-06: bluebird-helm's v0.18.27 release pushed its chart, then its metadata push failed: "tag artifacthub.io is already assigned to an image in this repository and cannot be updated due to immutability settings."
- 2026-11-06: nothing TJ runs reads ArtifactHub. Kubernetes-Manifests pulls the chart from `oci://registry-1.docker.io/zimmertr`.

## Alternatives rejected

- An immutability exception for the `artifacthub.io` tag: TJ keeps immutable tags as they are.
- Keeping the listing without the metadata job: the listing's metadata could never change again.

## Consequences

A chart is found by its OCI address, from its repo's README. The Docker Hub token is the only registry credential a chart release needs.
