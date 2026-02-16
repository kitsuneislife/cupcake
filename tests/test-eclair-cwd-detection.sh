#!/usr/bin/env bash
set -euo pipefail

echo "Test: eclair finds repo root when run from another CWD"

REPO_ROOT="$(pwd)"
# simulate running eclair from /tmp (or $HOME)
TMPDIR=$(mktemp -d)
pushd "$TMPDIR" >/dev/null
out=$(bash "$REPO_ROOT/scripts/eclair.sh" --dry-run --no-validate install htop 2>&1 || true)
popd >/dev/null
rm -rf "$TMPDIR"

if ! grep -q "would install 'htop'" <<<"$out"; then
  echo "eclair did not find repo root when run from other CWD:"; echo "$out"; exit 1
fi

echo "eclair cwd-detection test OK"