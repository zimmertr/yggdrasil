# 0042. A terraform module runs fmt, validate, test, tflint and Trivy in every repo with Terraform, in the images `compose.yml` pins

- Status: Accepted
- Date: 2026-11-06
- Decider: TJ, 2026-11-06, in #8, asked whether step 6.2 should write the Terraform checks for yggdrasil alone or once, as a shared module that TJs-Kubernetes-Service switches to later: "Shared module". The same day, on YAGNI, KISS and DRY: "YAGNI YAGNI YAGNI KISS KISS KISS DRY DRY DRY!!!!!"
- Issues and PRs: #8
- Cited in code as: decision record 0042, in `.github/workflows/terraform.yml`, `.github/workflows/checks.yml`, `scripts/terraform-each.sh`, `compose.yml` and the `Makefile`
- Guide: [`CLAUDE.md`](../../CLAUDE.md), the checks today

## Context

#8 step 6.2 planned five Terraform checks for yggdrasil's own stacks: `terraform fmt`, `terraform validate`, tflint, `terraform test` with mock providers, and Trivy's config scan. TJs-Kubernetes-Service runs the same five from its own `Makefile`, with its own pins. A second copy in yggdrasil would be two sets of pins and two scripts that drift, which global rule 26 (DRY) and record 0037's lint module were written to stop.

## Decision

- `.github/workflows/terraform.yml` is a module with five jobs, `fmt`, `validate`, `test`, `tflint` and `trivy`, and no inputs. A caller runs it on `pull_request` and sees `<caller job> / fmt` and the rest.
- All five run in the images `compose.yml` pins (`hashicorp/terraform`, `ghcr.io/terraform-linters/tflint`, `ghcr.io/aquasecurity/trivy`), read at the commit the caller pinned (record 0022), as the lint module does (0037). yggdrasil's CI and `make terraform` run the same images.
- `scripts/terraform-each.sh` runs `terraform validate` or `terraform test` in every directory it finds, because Terraform has neither check across directories. Found, not listed: a new stack or module is checked without a change to any caller, and the check names stay the same.
- Nothing reads state or a credential. `init` runs with `-backend=false`, and tests use mock providers.
- A caller's own `.tflint.hcl` and `trivy.yaml` replace tflint's bundled recommended rules and `defaults/trivy.yaml` (0006). Trivy scans Terraform only, since Dockerfiles have the docker-build module.
- yggdrasil's `checks.yml` calls the module from the PR's copy, so every change to it is tested before it releases.
- `scripts/` is a module path in `GitVersion.yml`, beside `.github/workflows/`, `actions/`, `defaults/` and `compose.yml`, so a change to the script releases (0004).
- Dependabot watches each stack's `.terraform.lock.hcl`, and its provider updates never merge themselves: once a merge applies the stack, a provider bump changes what the next apply does.

## Evidence

- 2026-11-06: TJs-Kubernetes-Service's `Makefile` runs `fmt-check`, `validate`, `lint` (tflint), `scan` (Trivy) and `test`, each in a pinned container, with Terraform 1.17.1, tflint v0.65.0 and Trivy 0.76.2.
- 2026-11-06, in Docker, before the first push: all five passed on `terraform/github`'s skeleton. A throwaway `terraform/probe` with a misaligned argument, an unused variable, a public `github_repository` and one failing test then failed four: `fmt` showed the diff, `test` reported "1 passed, 1 failed", tflint reported `terraform_unused_declarations`, and Trivy reported GIT-0001 (Critical, "Repository is public") and GIT-0003 (High, no vulnerability alerts). `validate` passed it, as it should for valid Terraform.

## Alternatives rejected

- yggdrasil's own targets, copied from TJs-Kubernetes-Service: a second copy of the checks and their pins.
- `hashicorp/setup-terraform`, `terraform-linters/setup-tflint` and `aquasecurity/trivy-action`: three more pins that move apart from `compose.yml`, so CI and a local run could disagree (0018, 0037).
- A matrix job per directory: each directory's name would join its check's name, so adding a stack would change the required checks.

## Consequences

- Trivy calls every public `github_repository` Critical (GIT-0001). The github stack's repos are mostly public on purpose, so #8's repo module turns that rule off in a `trivy.yaml` of yggdrasil's own, with the reason.
- TJs-Kubernetes-Service checks its committed `vars/<root>.tfvars` in `terraform test`, and the script doesn't. Its switch to the module adds that, or keeps that one target.
- A tool bump in `compose.yml` releases yggdrasil, and reaches callers with their next pin bump.
