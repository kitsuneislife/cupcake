{ config, pkgs, ... }:

{
  # Home-module: home/desktop/quickshell.nix
  # Purpose: run QuickShell as the user's top‑bar shell (autostart by default).

  # ensure quickshell package is available for the user
  home.packages = with pkgs; [ quickshell ];

  # Declarative systemd user service (managed by home-manager)
  systemd.user.services.quickshell = {
    description = "QuickShell top-bar shell (user)";
    serviceConfig = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
      Environment = "QT_QPA_PLATFORM=wayland";
    };
    wantedBy = [ "default.target" ];
  };


  home.file.".config/autostart/quickshell.desktop".text = ''
[Desktop Entry]
Type=Application
Name=QuickShell
Exec=${pkgs.quickshell}/bin/quickshell
X-GNOME-Autostart-enabled=true
'';

  # copy example QuickShell configuration (QML + settings) from repository
  home.file.".config/quickshell/config.json".source = ./quickshell/settings.json;
  home.file.".config/quickshell/main.qml".source = ./quickshell/main.qml;
  home.file.".config/quickshell/panel.qml".source = ./quickshell/panel.qml;
  # QuickShell looks for `shell.qml` or a `default/shell.qml` directory — provide both
  home.file.".config/quickshell/shell.qml".source = ./quickshell/shell.qml;
  home.file.".config/quickshell/default/shell.qml".source = ./quickshell/shell.qml;


}
