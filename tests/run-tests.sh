#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Running repository tests in $ROOT"

failures=0
passed=0

for t in tests/test-*.sh; do
  echo "\n--- running $t"
  if bash "$t"; then
    echo "[ok] $t"
    passed=$((passed+1))
  else
    echo "[FAIL] $t"
    failures=$((failures+1))
  fi
done

echo "\nSummary: $passed passed, $failures failed"
if [[ $failures -ne 0 ]]; then
  exit 1
fi
exit 0
