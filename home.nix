{ config, pkgs, inputs, ... }:

{
  # Modularized user configuration — small orchestrator that imports
  # program-specific home-manager fragments under `home/`.

  imports = [
    ./home/programs/git.nix
    ./home/programs/shell.nix
    ./home/programs/terminal.nix
    ./home/programs/editors.nix
    ./home/programs/packages.nix
    ./home/desktop/hyprland.nix
    ./home/desktop/theme.nix
  ];

  home.stateVersion = "25.11";
}
