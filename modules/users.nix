{ config, pkgs, ... }:

{
  # Module: modules/users.nix
  # Purpose: User and group definitions moved from `configuration.nix`.

  users.users.lukas = {
    isNormalUser = true;
    description = "lukas";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Add or override other users here as needed.
}
