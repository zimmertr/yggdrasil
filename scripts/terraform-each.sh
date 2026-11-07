#!/bin/sh
# Runs one Terraform check in every directory it applies to, for the terraform
# module and `make validate` / `make test` / `make trivy`. The directories are
# found, not listed, so a new stack or module is checked without a change to
# any caller. Decision record 0042.
#
# - validate and test: Terraform has neither check across directories, so each
#   directory is initialised and checked in turn. Runs in the terraform image.
# - trivy: a scan from the repo root reads each stack, but not the modules a
#   stack builds from data files it can't read, such as the github stack's
#   repos/. Scanning every directory on its own reaches them. Runs in the trivy
#   image, with the scan settings file as the second argument.
#
# Both images are Alpine, with BusyBox sh and find.
# Usage: terraform-each.sh validate|test|trivy [trivy.yaml]
set -eu

check=${1:-}

# The directory of each file found, once each. BusyBox's dirname takes one
# path, so sed trims the file name instead.
dirs_of() {
  find . -name "$1" -not -path '*/.terraform/*' -not -path './.yggdrasil/*' | sed 's|/[^/]*$||' | sort -u
}

case $check in
  validate | trivy) dirs=$(dirs_of '*.tf') ;;
  # A test file sits in its directory or in that directory's tests/.
  test) dirs=$(dirs_of '*.tftest.hcl' | sed 's|/tests$||' | sort -u) ;;
  *)
    echo "usage: $0 validate|test|trivy [trivy.yaml]" >&2
    exit 2
    ;;
esac

if [ -z "$dirs" ]; then
  echo "No Terraform to $check."
  exit 0
fi

if [ "$check" = trivy ]; then
  config=${2:?the trivy check takes the scan settings file}
  for dir in $dirs; do
    echo "==> trivy config $dir"
    trivy config --quiet --misconfig-scanners=terraform --exit-code=1 --config="$config" "$dir"
  done
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
