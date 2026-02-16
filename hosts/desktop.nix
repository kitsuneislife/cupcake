{ config, pkgs, ... }:

{
  # Host file: hosts/desktop.nix
  # Purpose: Host-specific overrides for the `desktop` machine.
  # This host imports the shared `hosts/default` fragments so `eclair`
  # edits will affect this host as well.

  imports = [ ./default/features.nix ];

  # Add host-specific configuration here (power, screens, hardware overrides).
}
