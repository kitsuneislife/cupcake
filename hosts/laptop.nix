{ config, pkgs, ... }:

{
  # Host file: hosts/laptop.nix
  # Purpose: Host-specific configuration for a laptop (power, screen, bluetooth).
  # This host imports the shared `hosts/default` fragments so `eclair` can
  # manage common toggles and packages.

  imports = [ ./default/features.nix ];

  # Add laptop-specific options here (services.tlp, power management, bluetooth).
}
