setup() {
  export HOME=$BATS_TEST_TMPDIR
  git config --global user.name test
  git config --global user.email test@localhost
  git config --global init.defaultBranch main
  cd "$BATS_TEST_TMPDIR"

  git init --quiet --bare remote.git
  git clone --quiet remote.git work 2> /dev/null
  cd work
  echo 1.2.2 > deploy.yml
  git add deploy.yml
  git commit --quiet --message init
  git push --quiet origin main

  # A stand-in for gh: it logs each call, and answers the open-PR lookup with
  # $OPEN_PR and `gh pr create` with a PR URL.
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/gh" << 'EOF'
#!/usr/bin/env bash
echo "$*" >> "$GH_LOG"
case "$1 $2" in
  "api repos/"*) echo "$OPEN_PR" ;;
  "pr create") echo "https://github.com/zimmertr/deploys/pull/7" ;;
esac
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH"

  export GH_LOG=$BATS_TEST_TMPDIR/gh.log
  export GITHUB_OUTPUT=$BATS_TEST_TMPDIR/output
  export REPO=zimmertr/deploys BRANCH=chore/bump TITLE="chore: bump to 1.2.3" BODY=body PATHS=deploy.yml
  export OPEN_PR=
  touch "$GH_LOG" "$GITHUB_OUTPUT"
}

open_pr() {
  bash "$BATS_TEST_DIRNAME/../../actions/open-pr/open-pr.sh"
}

@test "no change opens nothing" {
  run open_pr
  [ "$status" -eq 0 ]
  grep -qx operation=none "$GITHUB_OUTPUT"
  [ ! -s "$GH_LOG" ]
  run git ls-remote --exit-code origin chore/bump
  [ "$status" -eq 2 ]
}

@test "a change with no open PR pushes the branch and opens one" {
  echo 1.2.3 > deploy.yml
  run open_pr
  [ "$status" -eq 0 ]
  grep -qx operation=created "$GITHUB_OUTPUT"
  grep -qx number=7 "$GITHUB_OUTPUT"
  grep -q '^pr create --repo zimmertr/deploys --base main --head chore/bump' "$GH_LOG"
  [ "$(git log -1 --format=%s origin/chore/bump)" = "chore: bump to 1.2.3" ]
}

@test "a change with a PR open updates it" {
  echo 1.2.3 > deploy.yml
  OPEN_PR=5 run open_pr
  [ "$status" -eq 0 ]
  grep -qx operation=updated "$GITHUB_OUTPUT"
  grep -qx number=5 "$GITHUB_OUTPUT"
  grep -q '^pr edit 5 --repo zimmertr/deploys --title chore: bump to 1.2.3' "$GH_LOG"
}

@test "the branch starts fresh from the base, replacing an older run's" {
  git switch --quiet -c chore/bump
  echo 1.2.3 > deploy.yml
  git commit --quiet --all --message "chore: bump to 1.2.3"
  git push --quiet origin chore/bump
  git switch --quiet main

  echo 1.2.4 > deploy.yml
  run open_pr
  [ "$status" -eq 0 ]
  [ "$(git rev-parse origin/chore/bump~1)" = "$(git rev-parse origin/main)" ]
  [ "$(git show origin/chore/bump:deploy.yml)" = 1.2.4 ]
}

@test "only the given paths are committed" {
  echo 1.2.3 > deploy.yml
  echo stray > other.yml
  run open_pr
  [ "$status" -eq 0 ]
  [ "$(git diff --name-only origin/main origin/chore/bump)" = deploy.yml ]
}
