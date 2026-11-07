<!--
Managed by Terraform. The source is community-health-files/ in
zimmertr/yggdrasil, and each owner's .github repo gets a copy that GitHub
serves to every repo without its own. Edit the source, never a copy.
Record 0041.
-->

# Contributing

These are TJ's projects, so changes come through PRs that TJ reviews.

1. Branch from the latest `main`.
2. Make one change per PR, and title it `type(scope): summary`, such as `fix(ci): pin the base image`. The `PR Title` check refuses anything else. In a repo that releases, the type picks the version: `feat` is a minor, `fix` and the other types a patch, and a `!` a major.
3. Open the PR and let CI run. Every required check must pass, and every conversation must be resolved, before it can merge.
4. Update the docs and the README in the same PR wherever the change makes them untrue.

Never commit a secret. A security problem goes through the repository's **Security** tab, not an issue or a PR.
