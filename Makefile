# Every check CI runs, runnable the same way here. Each target runs in a
# container from compose.yml; nothing installs on the workstation
# (docs/DEVELOPMENT.md, decision record 0018).

# -T: no pseudo-terminal, so output redirected to a file carries no terminal
# control characters.
RUN := docker compose run --rm -T

# CI passes --format=github, so findings show as annotations on the PR.
ZIZMOR_ARGS ?=

.PHONY: check actionlint zizmor docs links em-dash

# Everything the PR checks run.
check: actionlint zizmor docs

# The actionlint job, over every workflow. The image bundles shellcheck, so
# run: blocks are checked too.
actionlint:
	$(RUN) actionlint -color

# The zizmor job: GitHub Actions security, over workflows, actions and
# dependabot.yml. The pedantic persona also fails a hash pin without its
# version comment, and any ${{ }} inside run:. Decision record 0019.
zizmor:
	$(RUN) zizmor --persona=pedantic $(ZIZMOR_ARGS) .

# The Docs job.
docs: links em-dash

# Every relative link in the docs, and the heading it points at. Offline:
# web links are not checked here.
links:
	$(RUN) lychee --offline --include-fragments --no-progress './**/*.md'

# No em dash in any doc (decision record 0017). The pattern is the character's
# UTF-8 bytes, so this file holds no em dash itself.
em-dash:
	$(RUN) shell sh -c '! grep -rn --include="*.md" --exclude-dir=.git "$$(printf "\342\200\224")" .'
