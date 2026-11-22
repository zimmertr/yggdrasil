setup() {
  export HOME=$BATS_TEST_TMPDIR
  git config --global user.name test
  git config --global user.email test@localhost
  git config --global init.defaultBranch main
  cd "$BATS_TEST_TMPDIR"
  git init --quiet
}

version() {
  "$BATS_TEST_DIRNAME/../../actions/version/version.sh" "$@"
}

# commit TITLE [FILE]
commit() {
  echo "$1" >> "${2:-file}"
  git add -A
  git commit --quiet --message "$1"
}

tag() {
  git tag "$1"
}

@test "the first release is 0.1.0" {
  commit "feat: start"
  run version next
  [ "$output" = 0.1.0 ]
}

@test "fix bumps the patch" {
  commit "feat: start"; tag v1.2.3
  commit "fix: a bug"
  run version next
  [ "$output" = 1.2.4 ]
}

@test "feat bumps the minor" {
  commit "feat: start"; tag v1.2.3
  commit "feat(api): a feature"
  run version next
  [ "$output" = 1.3.0 ]
}

@test "! bumps the major, whatever the type" {
  commit "feat: start"; tag v1.2.3
  commit "fix(api)!: a breaking fix"
  run version next
  [ "$output" = 2.0.0 ]
}

@test "several commits bump once, by the biggest" {
  commit "feat: start"; tag v1.2.3
  commit "fix: one"
  commit "feat: two"
  commit "docs: three"
  run version next
  [ "$output" = 1.3.0 ]
}

@test "no commit since the tag keeps the version" {
  commit "feat: start"; tag v1.2.3
  run version next
  [ "$output" = 1.2.3 ]
}

@test "a title the check would refuse still bumps the patch" {
  commit "feat: start"; tag v1.2.3
  commit "Update the README"
  run version next
  [ "$output" = 1.2.4 ]
}

@test "only the first line of a commit message counts" {
  commit "feat: start"; tag v1.2.3
  echo change >> file
  git commit --quiet --all --message "fix: a bug" --message "feat!: not this"
  run version next
  [ "$output" = 1.2.4 ]
}

@test "with paths, only commits that touch them count" {
  commit "feat: start"; tag v1.2.3
  commit "feat: settings only" settings.yml
  run version next actions defaults
  [ "$output" = 1.2.3 ]

  mkdir actions
  commit "fix: a module" actions/file
  run version next actions defaults
  [ "$output" = 1.2.4 ]
}

@test "the last tag counts, not a tag like latest" {
  commit "feat: start"; tag v1.2.3
  commit "fix: a bug"; tag latest
  run version next
  [ "$output" = 1.2.4 ]
}

@test "check accepts the titles a release reads" {
  for title in "feat: add" "fix(api): mend" "refactor!: rework" "build(deps): bump x to 2"; do
    run version check "$title"
    [ "$status" -eq 0 ]
  done
}

@test "check refuses anything else" {
  for title in "Add a thing" "feature: add" "Feat: add" "feat:add" "feat: " "feat(): add"; do
    run version check "$title"
    [ "$status" -eq 1 ]
  done
}
