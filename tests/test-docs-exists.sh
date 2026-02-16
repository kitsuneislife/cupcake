#!/usr/bin/env bash
set -euo pipefail

echo "Test: docs/03_Donut.md presence & content"
if [[ ! -f docs/03_Donut.md ]]; then
  echo "docs/03_Donut.md missing"; exit 1
fi
if ! grep -q "Donut — runtime & project helper" docs/03_Donut.md; then
  echo "docs/03_Donut.md doesn't contain expected heading"; exit 1
fi
# ensure .donutrc example exists
if ! grep -q "\.donutrc — project runtimes" docs/03_Donut.md; then
  echo "docs/03_Donut.md missing .donutrc example"; exit 1
fi

echo "docs present and valid"