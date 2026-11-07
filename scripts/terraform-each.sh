#!/bin/sh
# Runs `terraform validate` or `terraform test` in every directory that has
# Terraform, for the terraform module and `make validate` / `make test`.
# Terraform has neither check across directories, so each one is initialised
# and checked in turn. The directories are found, not listed, so a new stack or
# module is checked without a change to any caller. Decision record 0042.
#
# Runs inside the terraform image from compose.yml (BusyBox sh and find).
# Usage: terraform-each.sh validate|test
set -eu

check=${1:-}

# The directory of each file found, once each. BusyBox's dirname takes one
# path, so sed trims the file name instead.
dirs_of() {
  find . -name "$1" -not -path '*/.terraform/*' -not -path './.yggdrasil/*' | sed 's|/[^/]*$||' | sort -u
}

case $check in
  validate) dirs=$(dirs_of '*.tf') ;;
  # A test file sits in its directory or in that directory's tests/.
  test) dirs=$(dirs_of '*.tftest.hcl' | sed 's|/tests$||' | sort -u) ;;
  *)
    echo "usage: $0 validate|test" >&2
    exit 2
    ;;
esac

if [ -z "$dirs" ]; then
  echo "No Terraform to $check."
  exit 0
fi

# Terraform's working files go to the container's /tmp, not the checkout, so a
# run leaves nothing behind for the docs checks to read. Every directory's init
# reuses the providers the first one downloaded. Terraform warns if the cache
# folder is missing, so it is made first.
export TF_PLUGIN_CACHE_DIR=/tmp/terraform/plugin-cache
mkdir -p "$TF_PLUGIN_CACHE_DIR"

for dir in $dirs; do
  echo "==> terraform $check $dir"
  export TF_DATA_DIR="/tmp/terraform/data/$dir"
  # -backend=false: the checks need no state, so they need no HCP token.
  terraform -chdir="$dir" init -backend=false -input=false -no-color > /dev/null
  terraform -chdir="$dir" "$check" -no-color
done
