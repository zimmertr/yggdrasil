#!/usr/bin/env bash
#
# Posts a comment on PR, or edits the one an earlier run posted under the same
# HEADER. The hidden marker is marocchino/sticky-pull-request-comment's, so a
# comment that action posted is edited too.

set -euo pipefail

marker="<!-- Sticky Pull Request Comment${HEADER} -->"
if [[ -n $BODY_FILE ]]; then
  body=$(< "$BODY_FILE")
else
  body=$MESSAGE
fi
body+=$'\n'"$marker"

comments="repos/$GITHUB_REPOSITORY/issues/$PR/comments"
id=$(gh api --paginate "$comments" | jq -rn --arg marker "$marker" '
  [inputs[] | select(.user.login == "github-actions[bot]" and (.body | contains($marker))) | .id]
  | first // empty')

if [[ -n $id ]]; then
  gh api --method PATCH "repos/$GITHUB_REPOSITORY/issues/comments/$id" -f body="$body" > /dev/null
else
  gh api --method POST "$comments" -f body="$body" > /dev/null
fi
