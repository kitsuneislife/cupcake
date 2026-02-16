{ config, pkgs, ... }:

{
  # Home-module: home/programs/git.nix
  # Purpose: user-level Git settings (moved from `home.nix`).

  programs.git.settings = {
    enable = true;
    userName = "kitsuneislife";
    userEmail = "kitsuneislif3@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
