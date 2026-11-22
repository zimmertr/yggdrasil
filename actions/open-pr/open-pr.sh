#!/usr/bin/env bash
#
# Commits PATHS on BRANCH, fresh off the checked-out branch, force-pushes it,
# and opens a PR from it to that branch, or updates the one already open.
# Does nothing when PATHS hold no change.

set -euo pipefail

mapfile -t paths < <(sed '/^[[:space:]]*$/d' <<< "$PATHS")
git add -- "${paths[@]}"
if git diff --cached --quiet; then
  echo "operation=none" >> "$GITHUB_OUTPUT"
  exit 0
fi

base=$(git branch --show-current)
git switch --quiet -C "$BRANCH"
git -c user.name='github-actions[bot]' \
    -c user.email='41898282+github-actions[bot]@users.noreply.github.com' \
    commit --quiet --message "$TITLE"
git -c credential.helper='!gh auth git-credential' push --quiet --force origin "$BRANCH"

number=$(gh api "repos/$REPO/pulls?head=${REPO%%/*}:$BRANCH&state=open" --jq '.[0].number // empty')
if [[ -n $number ]]; then
  gh pr edit "$number" --repo "$REPO" --title "$TITLE" --body "$BODY" > /dev/null
  operation=updated
else
  url=$(gh pr create --repo "$REPO" --base "$base" --head "$BRANCH" --title "$TITLE" --body "$BODY")
  number=${url##*/}
  operation=created
fi

echo "operation=$operation" >> "$GITHUB_OUTPUT"
echo "number=$number" >> "$GITHUB_OUTPUT"
