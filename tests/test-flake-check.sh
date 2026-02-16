#!/usr/bin/env bash
set -euo pipefail

echo "Test: nix flake check"
# flake check is the canonical repository validation used by CI
nix flake check >/dev/null 2>&1
echo "flake check OK"