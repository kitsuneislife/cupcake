#!/usr/bin/env bash
set -euo pipefail

echo "Test: QuickShell is configured and autostarts"

# user packages should include quickshell
if ! grep -q "quickshell" home/programs/packages.nix; then
  echo "quickshell not present in home.packages"; exit 1
fi

# quickshell fragment must exist and declare unit/autostart
if [[ ! -f home/desktop/quickshell.nix ]]; then
  echo "home/desktop/quickshell.nix missing"; exit 1
fi

if ! grep -q "\.config/systemd/user/quickshell.service" home/desktop/quickshell.nix; then
  echo "quickshell unit file not declared in home/desktop/quickshell.nix"; exit 1
fi

if ! grep -q "\.config/autostart/quickshell.desktop" home/desktop/quickshell.nix; then
  echo "quickshell autostart entry not declared in home/desktop/quickshell.nix"; exit 1
fi

# ensure user settings include autostart = true
if ! grep -q "autostart" home/desktop/quickshell.nix; then
  echo "quickshell autostart not configured"; exit 1
fi

echo "quickshell config OK"