# Every check CI runs, runnable the same way here. Each target runs in a
# container from compose.yml; nothing installs on the workstation
# (docs/DEVELOPMENT.md, decision record 0018).

# -T: no pseudo-terminal, so output redirected to a file carries no terminal
# control characters.
RUN := docker compose run --rm -T

# CI passes --format=github, so findings show as annotations on the PR.
ZIZMOR_ARGS ?=

.PHONY: check actionlint shellcheck zizmor docs links em-dash gitversion

# Everything the PR checks run.
check: actionlint shellcheck zizmor docs gitversion

# The actionlint job, over every workflow. The image bundles shellcheck, so
# run: blocks are checked too.
actionlint:
	$(RUN) actionlint -color

# Also in the actionlint job: the same image's shellcheck, over every shell
# script outside the workflows. A script added elsewhere is added here.
SHELL_SCRIPTS := tests/gitversion/test.sh

shellcheck:
	$(RUN) --entrypoint shellcheck actionlint $(SHELL_SCRIPTS)

# The zizmor job: GitHub Actions security, over workflows, actions and
# dependabot.yml. The pedantic persona also fails a hash pin without its
# version comment, and any ${{ }} inside run:. Decision record 0019.
zizmor:
	$(RUN) zizmor --persona=pedantic $(ZIZMOR_ARGS) .

# The Docs job.
docs: links em-dash

# README.md and CLAUDE.md are named as well as globbed: a glob that matches
# nothing passes with nothing checked, but a named file that's missing fails.
DOCS_NAMED := README.md CLAUDE.md

# Every relative link in the docs, and the heading it points at. Offline:
# web links are not checked here.
links:
	$(RUN) lychee --offline --include-fragments --no-progress $(DOCS_NAMED) './**/*.md'

# No em dash in any doc (decision record 0017). The pattern is the character's
# UTF-8 bytes, so this file holds no em dash itself. Only grep's "no match"
# (exit 1) passes: a match (0) or a grep error (2) fails, so a broken grep
# can't pass silently.
em-dash:
	$(RUN) shell sh -c 'grep -rn --include="*.md" --exclude-dir=.git "$$(printf "\342\200\224")" . $(DOCS_NAMED); test $$? -eq 1'

# The GitVersion Engine job: the version rules in GitVersion.yml and
# defaults/GitVersion.yml, run by the pinned engine on made-up histories
# (decision record 0004).
gitversion:
	$(RUN) --entrypoint bash gitversion tests/gitversion/test.sh
