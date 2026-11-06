# Security Policy

## Supported Versions

yggdrasil's modules share one version. The only supported version is the
latest release under [Releases](https://github.com/zimmertr/yggdrasil/releases).
Older releases stay usable by their commit SHA but get no fixes; a fix ships as
the next release, and every consumer takes it within a day.

| Version        | Supported          |
| -------------- | ------------------ |
| Latest release | :white_check_mark: |
| Older releases | :x:                |

## Reporting a Vulnerability

Please report vulnerabilities privately through GitHub:
[Report a vulnerability](https://github.com/zimmertr/yggdrasil/security/advisories/new).
Do not open a public issue for security problems.

Include what you found, where it lives (a workflow, an action, a Terraform
stack), and how to reproduce it. A proof of concept helps but is not required.

What to expect:

- **Acknowledgement** within a few days. This is a one-person project, so
  response times are best effort.
- **Fix**: a confirmed vulnerability is fixed in the next release.
- **Credit** in the advisory and release notes, unless you'd rather not.

## Scope

In scope: this repository's reusable workflows, composite actions, Terraform,
and its own CI/CD workflows. That includes anything that could leak a secret,
let a pull request from a fork run with write access, or weaken a managed
repo's settings.

Out of scope: GitHub, Docker Hub, Cloudflare and HCP Terraform themselves, and
the repos that call these modules. Report a problem in a calling repo to that
repo.

There is no bounty program. Reports are still appreciated.
