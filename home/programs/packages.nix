{ config, pkgs, ... }:

{
  # MANAGED BY: home-manager — per-user packages (do NOT edit with eclair)
  # Home-module: home/programs/packages.nix
  # Purpose: central place for `home.packages` (moved from `home.nix`).
  # How to use: add/remove packages in the list below and import this file
  # from `home.nix`.

  home.packages = with pkgs; [
    microsoft-edge
    vscode
    discord
    htop
    # add your user packages here
  ];
} 
