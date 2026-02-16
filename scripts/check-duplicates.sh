#!/usr/bin/env bash
set -euo pipefail

# Check for duplicate package names between hosts/default/user-packages.nix
# (managed by eclair) and home/programs/packages.nix (managed by home-manager).

REPO_ROOT="$(dirname "$0")/.."
USER_PKGS="$REPO_ROOT/hosts/default/user-packages.nix"
HOME_PKGS="$REPO_ROOT/home/programs/packages.nix"

duplicates=0

# extract quoted package names from hosts/default/user-packages.nix
pkgs=$(grep -oP '"\K[^\"]+(?=")' "$USER_PKGS" || true)

# load hints (packages that are explicitly mapped)
hints=$(grep -oP '"\K[^\"]+(?=")\s*=\s*"(home|system)"' "$REPO_ROOT/hosts/default/package-hints.nix" 2>/dev/null || true)
# convert hints to a simple list of "pkg=side"
declare -A hintmap
if [[ -n "$hints" ]]; then
  # parse lines like: "name" = "home";
  while IFS= read -r line; do
    name=$(echo "$line" | sed -E 's/"([^\"]+)"\s*=\s*"(home|system)".*/\1/')
    side=$(echo "$line" | sed -E 's/"([^\"]+)"\s*=\s*"(home|system)".*/\2/')
    hintmap["$name"]="$side"
  done < <(grep -nE '"[^"]+"\s*=\s*"(home|system)"' "$REPO_ROOT/hosts/default/package-hints.nix" 2>/dev/null || true)
fi

for p in $pkgs; do
  # if hint exists and maps to one side only, skip duplicate check
  if [[ -n "${hintmap[$p]-}" ]]; then
    # if mapping says 'system' but package also appears in home packages, that's a duplicate that should be reported
    side=${hintmap[$p]}
    if [[ "$side" == "system" ]]; then
      if grep -qw "$p" "$HOME_PKGS"; then
        echo "Duplicate package found (mapped->system but present in home): $p" >&2
        duplicates=1
      fi
    else
      if grep -q "\b$p\b" "$HOME_PKGS"; then
        # mapped->home and present in system: report
        if grep -q "\b$p\b" "$USER_PKGS"; then
          echo "Duplicate package found (mapped->home but present in system): $p" >&2
          duplicates=1
        fi
      fi
    fi
    continue
  fi

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
