#!/usr/bin/env bash
set -euo pipefail

echo "Test: check-duplicates.sh"
out=$(bash ./scripts/check-duplicates.sh)
if [[ "$out" != *"No duplicates found"* ]]; then
  echo "Unexpected output from check-duplicates:"; echo "$out"
  exit 1
fi

echo "check-duplicates OK"