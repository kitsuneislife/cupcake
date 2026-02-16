#!/usr/bin/env bash
set -euo pipefail

echo "Test: docs/04_Donut.md presence & content"
if [[ ! -f docs/04_Donut.md ]]; then
  echo "docs/04_Donut.md missing"; exit 1
fi
if ! grep -q "Donut — runtime & project helper" docs/04_Donut.md; then
  echo "docs/04_Donut.md doesn't contain expected heading"; exit 1
fi
# ensure .donutrc example exists
if ! grep -q "\\.donutrc — project runtimes" docs/04_Donut.md; then
  echo "docs/04_Donut.md missing .donutrc example"; exit 1
fi

echo "docs present and valid"