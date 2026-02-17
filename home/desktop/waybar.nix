{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ./waybar/style.css;
    settings = {
      mainBar = builtins.fromJSON (builtins.readFile ./waybar/config.jsonc);
    };
  };
}
