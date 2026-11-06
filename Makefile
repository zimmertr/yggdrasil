# Every check CI runs, runnable the same way here. Each target runs in a
# container from compose.yml; nothing installs on the workstation
# (docs/DEVELOPMENT.md).

# -T: no pseudo-terminal, so output redirected to a file (the job summary)
# carries no terminal control characters.
RUN     := docker compose run --rm -T
INSTALL := pip install -q --require-hashes -r requirements-dev.txt

.PHONY: test test-one coverage-summary lint actionlint lock

# The suite under line and branch coverage, as the test job runs it.
test:
	$(RUN) python sh -c '$(INSTALL) && \
	  python -m coverage run -m unittest discover -s tests -t . -v && \
	  python -m coverage report'

# One module, for iterating on a failure: make test-one MODULE=tests.test_check_policy
test-one:
	$(RUN) python sh -c '$(INSTALL) && python -m unittest $(MODULE) -v'

# The coverage table as markdown, for the job summary. Reads the data `make
# test` left behind.
coverage-summary:
	@$(RUN) python sh -c '$(INSTALL) && python -m coverage report --format=markdown'

# The Lint job: ruff under ruff.toml.
lint:
	$(RUN) ruff check .

# The actionlint job, over every workflow. The image bundles shellcheck, so
# run: blocks are checked too.
actionlint:
	$(RUN) actionlint -color

# Not a check: rewrites requirements-dev.txt from requirements-dev.in, with
# hashes, on the image's own Python. Add --upgrade-package NAME to move one pin.
lock:
	$(RUN) python sh -c "pip install -q 'pip<26' pip-tools==7.5.3 && \
	  pip-compile -q --generate-hashes --allow-unsafe --strip-extras \
	    --output-file=requirements-dev.txt requirements-dev.in"
