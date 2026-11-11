<!--
Managed by Terraform. The source is community-health-files/ in
zimmertr/yggdrasil, and each owner's .github repo gets a copy that GitHub
serves to every repo without its own. Edit the source, never a copy.
Record 0055.
-->

# Contributing

These are one-person projects, so changes come through PRs that TJ reviews. For a large change, open an issue first, so the approach gets discussed before you build it.

If you send a change:

1. Branch from the latest `main`.
2. Make one change per PR, and title it `type(scope): summary`, such as `fix(parser): handle an empty file`. In a repo that cuts releases the title picks the version: a `!` before the colon is a major, `feat` a minor, and anything else a patch.
3. Where the repo builds something, build and run it in Docker, as its README shows, so nothing installs on your machine. Where it has a `Makefile`, its targets are the checks CI runs.
4. Where the repo has tests, a change in behaviour ships with one in the same PR.
5. Where the repo has a `docs/` folder, update the page that owns the topic in the same PR.
6. Open the PR and read what its checks say.

Never commit a secret, a token or personal data.

Security problems go through private reporting, not issues: open the repository's **Security** tab and choose **Report a vulnerability**.
