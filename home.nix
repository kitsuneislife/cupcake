{ config, pkgs, inputs, ... }:

{
  # Modularized user configuration — small orchestrator that imports
  # program-specific home-manager fragments under `home/`.

  imports = [
    ./home/programs/git.nix
    ./home/programs/shell.nix
    ./home/programs/terminal.nix
    ./home/programs/editors.nix
    # Use the tracked template if the per-user packages file isn't present in the flake
    (if builtins.pathExists ./home/programs/packages.nix then ./home/programs/packages.nix else ./home/programs/packages.nix.template)
    ./home/desktop/vicinae.nix
    ./home/desktop/hyprland.nix
    ./home/desktop/waybar.nix
    ./home/desktop/theme.nix
  ];

  home.stateVersion = "25.11";
}
