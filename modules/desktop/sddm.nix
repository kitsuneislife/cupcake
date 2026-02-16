{ config, pkgs, ... }:

{
  # Module: modules/desktop/sddm.nix
  # Purpose: SDDM and display manager settings moved from `configuration.nix`.
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # Further SDDM theming or Seat configuration can be added here.
}
