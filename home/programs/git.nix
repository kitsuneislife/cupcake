{ config, pkgs, localCfg, ... }:
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