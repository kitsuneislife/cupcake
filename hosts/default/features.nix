{ config, pkgs, ... }:

{
  # MANAGED BY: eclair — feature toggles (do NOT edit manually; use ./scripts/eclair.sh)
  # hosts/default/features.nix
  # Purpose: central place for small feature toggles managed by `eclair`.
  # How `eclair` uses this file: it looks for lines like
  # `...<name>.enable = true|false;` and toggles the boolean.
  # Keep one feature per line and prefer the pattern <namespace>.<name>.enable

  # Networking
  networking.networkmanager.enable = true;

  # Display manager / desktop
  services.displayManager.sddm.enable = true;
  programs.hyprland.enable = true;

  # Example infrastructure features (toggleable)
  services.openssh.enable = true;
  hardware.bluetooth.enable = false;

  # Add new `.enable` lines here — `eclair list` will show them automatically.
}
