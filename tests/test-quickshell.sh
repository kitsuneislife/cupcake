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

if ! grep -q "systemd.user.services.quickshell" home/desktop/quickshell.nix; then
  echo "quickshell systemd.user.services not declared in home/desktop/quickshell.nix"; exit 1
fi

if ! grep -q "\.config/autostart/quickshell.desktop" home/desktop/quickshell.nix; then
  echo "quickshell autostart entry not declared in home/desktop/quickshell.nix"; exit 1
fi

# example config directory should exist and quickshell.nix should reference example files
if [[ ! -d home/desktop/quickshell ]]; then
  echo "example quickshell config directory missing"; exit 1
fi

# ensure shell.qml is present (quickshell's expected entrypoint)
if [[ ! -f home/desktop/quickshell/shell.qml ]]; then
  echo "quickshell example shell.qml missing"; exit 1
fi

if ! grep -q "\.config/quickshell/main.qml" home/desktop/quickshell.nix; then
  echo "quickshell.nix does not reference main.qml"; exit 1
fi

if ! grep -q "\.config/quickshell/shell.qml" home/desktop/quickshell.nix; then
  echo "quickshell.nix does not reference shell.qml"; exit 1
fi

if ! grep -q "\.config/quickshell/config.json" home/desktop/quickshell.nix; then
  echo "quickshell.nix does not reference config.json"; exit 1
fi

echo "quickshell config OK"