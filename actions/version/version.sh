#!/usr/bin/env bash
#
# version.sh check TITLE      Fails unless TITLE is a PR title the release can read.
# version.sh next [PATH...]   Prints the next version: the last tag, bumped by the
#                             commits since it that touch PATH, or by every commit.
#
# A title is `type(scope): summary`, and the scope is optional. `feat` bumps the
# minor, a `!` before the colon bumps the major, and any other type the patch.
# Several commits since the last tag bump once, by the biggest of their bumps.

set -euo pipefail

types='feat|fix|perf|refactor|chore|docs|style|test|ci|build'
title_pattern="^($types)(\([^)]+\))?(!)?: ."

bump_for() {
  if [[ ! $1 =~ $title_pattern ]]; then
    echo patch
  elif [[ -n ${BASH_REMATCH[3]} ]]; then
    echo major
  elif [[ ${BASH_REMATCH[1]} == feat ]]; then
    echo minor
  else
    echo patch
  fi
}

check() {
  if [[ ! $1 =~ $title_pattern ]]; then
    echo "::error::The PR title must be 'type(scope): summary', with a type from: ${types//|/, }"
    exit 1
  fi
}

next() {
  local tag
  if ! tag=$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null); then
    echo 0.1.0
    return
  fi

  local bump='none' title
  while IFS= read -r title; do
    case $(bump_for "$title") in
      major) bump='major' ;;
      minor) [[ $bump == major ]] || bump='minor' ;;
      patch) [[ $bump != none ]] || bump='patch' ;;
    esac
  done < <(git log --format=%s "$tag..HEAD" -- "$@")

  local major minor patch
  IFS=. read -r major minor patch <<< "${tag#v}"
  case $bump in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "$major.$((minor + 1)).0" ;;
    patch) echo "$major.$minor.$((patch + 1))" ;;
    none) echo "$major.$minor.$patch" ;;
  esac
}

case ${1-} in
  check) check "${2-}" ;;
  next) shift; next "$@" ;;
  *) echo "Usage: $0 check TITLE | next [PATH...]" >&2; exit 2 ;;
esac
