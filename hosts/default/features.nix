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

  # Audio
  hardware.pulseaudio.enable = false;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.pulse.enable = true;
  services.pipewire.jack.enable = true;

  # Brightness control
  programs.light.enable = true;

  # Add new `.enable` lines here — `eclair list` will show them automatically.
}