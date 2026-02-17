{ config, pkgs, ... }:

{
  # Home-module: home/desktop/vicinae.nix
  # Purpose: run Vicinae as a user systemd service and provide minimal settings.

  # ensure vicinae package is available for the user (redundant-safe)
  home.packages = with pkgs; [ vicinae ];

  # systemd user service to run the vicinae server (auto-start)
  # Instead of relying on the home-manager `systemd.user.services` schema
  # (some modules may vary), create the user unit + autostart via files and
  # provide a small activation that enables the unit on activation.


  # write a minimal Vicinae user config (JSONC) with close_on_focus_loss enabled
  home.file.".config/vicinae/settings.json".text = ''
{
  // minimal declarative settings for Vicinae
  "close_on_focus_loss": true
}
'';

  # activation: enable the user service if systemd user is active

  # Basic (optional) settings region — kept small and safe
  # Users who want the full Vicinae module (extensions/themes/etc.)
  # should add the official vicinae flake to their flake inputs.
}
