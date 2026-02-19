{ config, pkgs, ... }:

{
  # Top-level configuration — now modularized. Active options have been moved
  # into `/etc/nixos/modules/*`. Keep global overrides here if needed.

  nix.settings.experimental-features = ["nix-command" "flakes"];

  imports = [
    ./hardware-configuration.nix
    ./hosts/default/features.nix   # centrally-managed feature toggles (eclair)
    ./modules/boot.nix
    ./modules/networking.nix
    ./modules/users.nix
    ./modules/services.nix
    ./modules/desktop
    ./modules/nvidia.nix
  ];

  # Keep the system state version at top-level
  system.stateVersion = "25.11";
}
