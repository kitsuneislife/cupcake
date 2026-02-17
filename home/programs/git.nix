{ config, pkgs, ... }:

let
  localPath = /etc/nixos/local.nix;
  localCfg = if builtins.pathExists localPath then import localPath else {
    userName = "Your Name";
    userEmail = "you@example.org";
  };
in
{
  programs.git = {
    enable = true;
    settings = {
      user.name = localCfg.userName;
      user.email = localCfg.userEmail;
      init.defaultBranch = "main";
    };
  };
}