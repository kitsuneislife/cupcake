#!/usr/bin/env bash
set -euo pipefail

echo "Test: eclair (dry-run install + list + update)"

# dry-run install should not modify files and should print a dry-run message
out=$(bash ./scripts/eclair.sh --dry-run --no-validate install htop)
if ! grep -q "\(dry-run\) would install 'htop'" <<<"$out"; then
  echo "eclair dry-run install did not report expected message:"; echo "$out"
  exit 1
fi

# list should show Installed Packages and a known package (docker exists in user-packages)
out=$(bash ./scripts/eclair.sh list)
if ! grep -q "Installed Packages" <<<"$out"; then
  echo "eclair list missing 'Installed Packages' header"; echo "$out"; exit 1
fi
if ! grep -q "docker" <<<"$out"; then
  echo "eclair list did not include 'docker' (expected in hosts/default/user-packages.nix)"; echo "$out"; exit 1
fi

# update in dry-run should validate flake and return 0
bash ./scripts/eclair.sh --dry-run update >/dev/null 2>&1

echo "eclair dry-run tests OK"