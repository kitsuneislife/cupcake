{ config, pkgs, ... }:

{
  # Home-module: home/programs/shell.nix
  # Purpose: Shell settings and aliases (moved from `home.nix`).

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      nixup = "sudo nixos-rebuild switch";
    };
  };
}
