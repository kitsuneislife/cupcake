{ config, pkgs, ... }:

let
  localPath = ../local.nix;
  localCfg = if builtins.pathExists localPath then import localPath else {};
  uname = if localCfg ? username then localCfg.username else "lukas";
  displayName = if localCfg ? userName then localCfg.userName else uname;
in
{
  # Module: modules/users.nix
  # Purpose: User and group definitions moved from `configuration.nix`.

  users.users = {
    "${uname}" = {
      isNormalUser = true;
      description = displayName;
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [];
    };
  };

  # Add or override other users here as needed.
}
