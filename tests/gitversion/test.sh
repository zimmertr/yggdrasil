#!/usr/bin/env bash
# The GitVersion behaviour yggdrasil's releases rest on, checked against the
# pinned engine on made-up histories (decision records 0004 and 0025), so Dependabot's
# bump of the image runs it too. `make gitversion` runs it in the
# gittools/gitversion image from compose.yml, which ships git and bash.
#
# Each case builds a fresh repo with one of the two config files, then checks
# GitVersion's SemVer and the commit its Sha names. The Sha matters: when the
# newest commits are skipped, it is the last commit that counted, and the
# release job (#4 item 2.4) must not mistake that for HEAD.
set -euo pipefail

ROOT=$(pwd)
OWN=$ROOT/GitVersion.yml
CONSUMER=$ROOT/defaults/GitVersion.yml
WORK=$(mktemp -d)
failures=0

git config --global user.email test@example.com
git config --global user.name test
git config --global init.defaultBranch main

start() { # name, config
  CASE=$1
  REPO=$WORK/$CASE
  git init -q "$REPO"
  cp "$2" "$REPO/GitVersion.yml"
  n=0
}

# Each commit lands a minute after the last, as real merges do. With every
# commit in the same second, GitVersion applied one patch for a whole run of
# commits, feat!: and all (record 0004). A case stays under 60 commits.
commit() { # message, path...
  local message=$1 path
  shift
  n=$((n + 1))
  GIT_AUTHOR_DATE=2026-11-01T00:$(printf %02d "$n"):00Z
  export GIT_AUTHOR_DATE GIT_COMMITTER_DATE=$GIT_AUTHOR_DATE
  for path in "$@"; do
    mkdir -p "$(dirname "$REPO/$path")"
    echo "$n" >> "$REPO/$path"
  done
  git -C "$REPO" add -A
  git -C "$REPO" commit -q -m "$message"
}

tag() {
  git -C "$REPO" tag "$1"
}

expect() { # semver, the ref GitVersion's Sha must name (default HEAD)
  local want got
  want="$1 $(git -C "$REPO" rev-parse "${2:-HEAD}")"
  got=$(/tools/dotnet-gitversion "$REPO" /nocache /output json /format '{SemVer} {Sha}' 2>&1 | tail -n 1)
  if [ "$got" = "$want" ]; then
    echo "ok   $CASE: $1 at ${2:-HEAD}"
  else
    echo "FAIL $CASE: want $want, got $got"
    failures=$((failures + 1))
  fi
}

MODULE=.github/workflows/module.yml

# yggdrasil's own file: only a commit that touches a module path releases.

start first-release "$OWN"
commit 'feat: add a module' "$MODULE"
expect 0.1.0

start module-fix "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'fix(module): handle an empty input' "$MODULE"
expect 0.1.1

start module-feat "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'feat(module): add an input' actions/thing/action.yml
expect 0.2.0

start module-breaking "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'feat!: rename an input' defaults/GitVersion.yml
expect 1.0.0

start settings-only-breaking "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'feat!: change every repo setting' terraform/repos.tf
expect 0.1.0 v0.1.0

start docs-only "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'docs: explain the modules' README.md docs/USAGE.md
expect 0.1.0 v0.1.0

# #3's history: the skipped commits after a module fix leave its patch, and
# Sha names the fix, not HEAD.
start skipped-after-a-fix "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'fix(module): handle an empty input' "$MODULE"
commit 'feat!: change every repo setting' terraform/repos.tf
commit 'docs: explain the modules' README.md
expect 0.1.1 HEAD~2

start module-and-settings-together "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'feat!: rename an input and every setting' "$MODULE" terraform/repos.tf
expect 1.0.0

# yggdrasil's own CI lives beside the modules, so changing it releases a patch.
start own-ci "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'ci: run the checks on main' .github/workflows/checks.yml
expect 0.1.1

# The title alone picks the bump.

start body-is-not-the-title "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit $'fix: handle an empty input\n\nfeat!: a line that starts like a title\n\nBREAKING CHANGE: a footer' "$MODULE"
expect 0.1.1

start scope-ends-at-its-paren "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'fix(module): explain feat(api)!: titles' "$MODULE"
expect 0.1.1

start any-case "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'Fix!: drop an input' "$MODULE"
expect 1.0.0

start dependabot-title "$OWN"
commit 'feat: add a module' "$MODULE"
tag v0.1.0
commit 'build(deps): bump actions/checkout from 7.0.0 to 7.0.1' "$MODULE"
expect 0.1.1

# The default a caller gets: every merge releases.

start consumer-first-release "$CONSUMER"
commit 'feat: add the app' src/app.py
expect 0.1.0

start consumer-docs "$CONSUMER"
commit 'feat: add the app' src/app.py
tag v0.1.0
commit 'docs: explain the app' README.md
expect 0.1.1

start consumer-past-the-seed "$CONSUMER"
commit 'feat: add the app' src/app.py
tag v1.2.0
commit 'fix: handle an empty response' src/app.py
expect 1.2.1

if [ "$failures" -gt 0 ]; then
  echo "$failures case(s) failed"
  exit 1
fi
