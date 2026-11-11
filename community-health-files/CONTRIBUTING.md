<!--
Managed by Terraform. The source is community-health-files/ in
zimmertr/yggdrasil, and each owner's .github repo gets a copy that GitHub
serves to every repo without its own. Edit the source, never a copy.
Record 0055.
-->

# Contributing

Thanks for your interest in contributing. Bug reports, fixes, documentation and new features are all welcome.

## Before you start

- For a bug or a small fix, open a pull request directly.
- For a larger change, open an issue first, so the approach is agreed before you put time into it.
- Questions are welcome as issues too.

## Sending a pull request

1. Fork the repository and branch from the latest `main`.
2. Keep each pull request to one change, and title it `type(scope): summary`, such as `fix(parser): handle an empty file`. In a repository that publishes releases, the title sets the next version: a `!` before the colon is a major, `feat` a minor, and anything else a patch.
3. Where the project builds something, build and run it in Docker as its README shows, so nothing is installed on your machine. Where it has a `Makefile`, its targets are the checks CI runs.
4. Where the project has tests, add or update one when you change behaviour.
5. Where the project has a `docs/` folder, update the page that covers what you changed.
6. Open the pull request and make sure its checks pass. Every pull request gets a review.

Please don't commit secrets, tokens or personal data.

## Reporting a security problem

Please report security problems privately and not in a public issue: open the repository's **Security** tab and choose **Report a vulnerability**.
