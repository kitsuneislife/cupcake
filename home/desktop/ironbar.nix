{ config, pkgs, ... }:

{
  home.packages = [ pkgs.ironbar ];

  xdg.configFile."ironbar/config.json".source = ./ironbar/config.json;
  xdg.configFile."ironbar/style.css".source = ./ironbar/style.css;

  systemd.user.services.ironbar = {
    Unit = {
      Description = "Ironbar status bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.ironbar}/bin/ironbar";
      Restart = "always";
      RestartSec = "1sec";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
