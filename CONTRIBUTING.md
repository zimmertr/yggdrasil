# Contributing

yggdrasil has one maintainer. For a large change, open an issue first, so the approach gets discussed before you build it.

If you send a change:

- Every check CI runs is a `make` target at the repository root (`make check` runs them all), and each one runs in Docker. Nothing runs on the host. [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) lists them.
- Every change ships with tests in the same PR, and CI runs them.
- Workflows pass zizmor's pedantic audits (actions pinned to a full SHA with `# vX.Y.Z`, no `${{ }}` inside `run:`, checkouts without credentials, no `pull_request_target`), and docs have working links and no em dashes.
- The PR title is `type(scope): summary`, such as `fix(release): keep the tag when the push is retried`. The title picks the next version of every module. A change that breaks a caller (a removed input, a new required one) carries `!` before the colon.
- Every module takes its configuration from its caller as inputs. Don't add per-repo settings for a calling repo here.
- The repo is public. No tokens, ids or personal data in code, fixtures or logs, and never the contents of a private repo.
- No workflow uses `pull_request_target`.

Security problems go through private reporting, not issues ([the security policy](https://github.com/zimmertr/yggdrasil/security/policy)).
