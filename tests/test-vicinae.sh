#!/usr/bin/env bash
set -euo pipefail

echo "Test: Vicinae is configured as default launcher"

# hyprland config should contain the Vicinae binding (SPACE or Tab toggle acceptable)
if ! (grep -q "SUPER, SPACE, exec, vicinae" home/desktop/hyprland.nix || grep -q "vicinae toggle" home/desktop/hyprland.nix); then
  echo "hyprland keybind for vicinae not found"; exit 1
fi

# user packages should include vicinae
if ! grep -q "vicinae" home/programs/packages.nix; then
  echo "vicinae not present in home.packages"; exit 1
fi
# vicinae fragment must create a unit file and an autostart entry
if [[ ! -f home/desktop/vicinae.nix ]]; then
  echo "home/desktop/vicinae.nix missing"; exit 1
fi
if ! grep -q "\.config/systemd/user/vicinae.service" home/desktop/vicinae.nix; then
  echo "vicinae unit file not declared in home/desktop/vicinae.nix"; exit 1
fi
if ! grep -q "\.config/autostart/vicinae.desktop" home/desktop/vicinae.nix; then
  echo "vicinae autostart entry not declared in home/desktop/vicinae.nix"; exit 1
fi

# ensure user settings include close_on_focus_loss = true
if ! grep -q "close_on_focus_loss" home/desktop/vicinae.nix; then
  echo "vicinae close_on_focus_loss not configured"; exit 1
fi
echo "vicinae config OK"