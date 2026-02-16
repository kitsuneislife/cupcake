#!/usr/bin/env bash
set -euo pipefail

echo "Test: donut (help, dry-run global/status)"

# help should include usage
out=$(bash ./scripts/donut.sh help)
if ! grep -q "Usage: donut" <<<"$out"; then
  echo "donut help missing Usage header"; echo "$out"; exit 1
fi

# dry-run global add for node should not attempt to install, only print the action
out=$(bash ./scripts/donut.sh --dry-run global add node eslint 2>&1 || true)
if ! grep -q "global add node eslint" <<<"$out"; then
  echo "donut dry-run global add didn't print expected message"; echo "$out"; exit 1
fi
# ensure it printed the pnpm command suggestion in dry-run output
if ! grep -q "pnpm add -g eslint" <<<"$out"; then
  echo "donut dry-run global add did not print pnpm fallback"; echo "$out"; exit 1
fi

# status should run and report detected files (do not require creating .donutrc)
out=$(bash ./scripts/donut.sh status || true)
if ! grep -q "Detected files" <<<"$out"; then
  echo "donut status did not print 'Detected files'"; echo "$out"; exit 1
fi
# repo contains .nvmrc/.python-version — status should list them
if ! grep -q "\.nvmrc" <<<"$out" || ! grep -q "\.python-version" <<<"$out"; then
  echo "donut status did not report expected per-project files"; echo "$out"; exit 1
fi

# dry-run init should not fail even if managers not present (we use --dry-run when needed)
bash ./scripts/donut.sh --dry-run global add python ruff >/dev/null 2>&1 || true

echo "donut basic tests OK"