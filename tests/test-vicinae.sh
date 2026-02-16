#!/usr/bin/env bash
set -euo pipefail

echo "Test: Vicinae is configured as default launcher"

# hyprland config should contain the Vicinae binding
if ! grep -q "SUPER, Tab, exec, vicinae toggle" home/desktop/hyprland.nix; then
  echo "hyprland keybind for vicinae not found"; exit 1
fi

# user packages should include vicinae
if ! grep -q "vicinae" home/programs/packages.nix; then
  echo "vicinae not present in home.packages"; exit 1
fi
# vicinae service fragment exists and configures a systemd user service
if [[ ! -f home/desktop/vicinae.nix ]]; then
  echo "home/desktop/vicinae.nix missing"; exit 1
fi
if ! grep -q "systemd.user.services.vicinae" home/desktop/vicinae.nix; then
  echo "vicinae systemd.user service not configured in home/desktop/vicinae.nix"; exit 1
fi
echo "vicinae config OK"