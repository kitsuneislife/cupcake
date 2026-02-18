{ config, pkgs, lib, ... }:

let
  # Wallpaper path
  wallpaper = "${config.home.homeDirectory}/Pictures/Wallpapers/default.png"; 
in
{
  home.packages = with pkgs; [ swww ];

  systemd.user.services.swww = {
    Unit = {
      Description = "swww wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      ExecStop = "${pkgs.swww}/bin/swww kill";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Script to set wallpaper after daemon starts
  systemd.user.services.swww-init = {
    Unit = {
      Description = "Set initial wallpaper with swww";
      After = [ "swww.service" ];
      Requires = [ "swww.service" ];
      ParteOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.swww}/bin/swww img ${wallpaper} --transition-type grow --transition-pos 0.5,0.5 --transition-step 90";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
