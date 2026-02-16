#!/usr/bin/env bash
set -euo pipefail

# Check for duplicate package names between hosts/default/user-packages.nix
# (managed by eclair) and home/programs/packages.nix (managed by home-manager).

REPO_ROOT="$(dirname "$0")/.."
USER_PKGS="$REPO_ROOT/hosts/default/user-packages.nix"
HOME_PKGS="$REPO_ROOT/home/programs/packages.nix"

duplicates=0

# extract quoted package names from hosts/default/user-packages.nix
pkgs=$(grep -oP '"\K[^"]+(?=")' "$USER_PKGS" || true)

for p in $pkgs; do
  if grep -qw "$p" "$HOME_PKGS"; then
    echo "Duplicate package found: $p" >&2
    duplicates=1
  fi
done

if (( duplicates )); then
  echo "Found duplicate packages between $USER_PKGS and $HOME_PKGS" >&2
  exit 1
fi

echo "No duplicates found"
exit 0
