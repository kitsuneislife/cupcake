{ config, pkgs, ... }:

let
  # local.nix (optional, gitignored) can override these values. Example in local.nix.template
  localPath = ../../local.nix;
  localCfg = if builtins.pathExists localPath then import localPath else {
    username = "youruser";
    userName = "Your Name";
    userEmail = "you@example.org";
  };
in
{
  # Home-module: home/programs/git.nix
  # Purpose: user-level Git settings (moved from `home.nix`).

  programs.git.settings = {
    enable = true;
    userName = localCfg.userName;
    userEmail = localCfg.userEmail;
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
