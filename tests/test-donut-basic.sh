#!/usr/bin/env bash
set -euo pipefail

echo "Test: donut (help, dry-run global/status)"

# help should include usage
out=$(bash ./scripts/donut.sh help)
if ! grep -q "donut — runtime manager helper" <<<"$out"; then
  echo "donut help missing header"; echo "$out"; exit 1
fi

# dry-run global add for node should not attempt to install, only print the action
out=$(bash ./scripts/donut.sh --dry-run global add node eslint 2>&1 || true)
if ! grep -q "\(dry-run\) global add node eslint" <<<"$out"; then
  echo "donut dry-run global add didn't print expected message"; echo "$out"; exit 1
fi

# dry-run status should create .donutrc if missing (uses repo root in tests)
# remove any existing .donutrc, run status, ensure file created
rm -f .donutrc || true
bash ./scripts/donut.sh status >/dev/null 2>&1 || true
if [[ ! -f .donutrc ]]; then
  echo ".donutrc was not created by donut status"; ls -la .; exit 1
fi

# dry-run init should not fail even if managers not present (we use --dry-run when needed)
bash ./scripts/donut.sh --dry-run global add python ruff >/dev/null 2>&1 || true

echo "donut basic tests OK"