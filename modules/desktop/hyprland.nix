{ config, pkgs, ... }:

{
  # Module: modules/desktop/hyprland.nix
  # Purpose: System-level Hyprland options (moved from configuration.nix).
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  # User-level session config remains in `home/desktop/hyprland.nix`.
}
