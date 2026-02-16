{ config, pkgs, ... }:

{
  # Home-module: home/desktop/quickshell.nix
  # Purpose: run QuickShell as the user's top‑bar shell (autostart by default).

  # ensure quickshell package is available for the user
  home.packages = with pkgs; [ quickshell ];

  # systemd user service to run the QuickShell server (auto-start)
  home.file.".config/systemd/user/quickshell.service".text = ''
[Unit]
Description=QuickShell top-bar shell (user)

[Service]
ExecStart=${pkgs.quickshell}/bin/quickshell
Restart=on-failure
Environment=QT_QPA_PLATFORM=wayland

[Install]
WantedBy=default.target
'';

  home.file.".config/autostart/quickshell.desktop".text = ''
[Desktop Entry]
Type=Application
Name=QuickShell
Exec=${pkgs.quickshell}/bin/quickshell
X-GNOME-Autostart-enabled=true
'';

  # minimal QuickShell user config: enable autostart by default
  home.file.".config/quickshell/config.json".text = ''
{
  "autostart": true,
  "position": "top"
}
'';

  # activation: enable the user service if systemd user is active
  home.activation.quickshell-enable = ''
    if command -v systemctl >/dev/null 2>&1; then
      systemctl --user daemon-reload || true
      systemctl --user enable --now quickshell.service || true
    fi
  '';
}
