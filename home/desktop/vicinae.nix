{ config, pkgs, ... }:

{
  # Home-module: home/desktop/vicinae.nix
  # Purpose: run Vicinae as a user systemd service and provide minimal settings.

  # ensure vicinae package is available for the user (redundant-safe)
  home.packages = with pkgs; [ vicinae ];

  # systemd user service to run the vicinae server (auto-start)
  # Instead of relying on the home-manager `systemd.user.services` schema
  # (some modules may vary), create the user unit + autostart via files and
  # provide a small activation that enables the unit on activation.

  home.file.".config/systemd/user/vicinae.service".text = ''
[Unit]
Description=Vicinae launcher server (user)

[Service]
ExecStart=${pkgs.vicinae}/bin/vicinae server
Restart=on-failure
Environment=USE_LAYER_SHELL=1

[Install]
WantedBy=default.target
'';

  home.file.".config/autostart/vicinae.desktop".text = ''
[Desktop Entry]
Type=Application
Name=Vicinae
Exec=${pkgs.vicinae}/bin/vicinae server
X-GNOME-Autostart-enabled=true
'';

  # activation: enable the user service if systemd user is active
  home.activation.vicinae-enable = ''
    if command -v systemctl >/dev/null 2>&1; then
      systemctl --user daemon-reload || true
      systemctl --user enable --now vicinae.service || true
    fi
  '';

  # Basic (optional) settings region — kept small and safe
  # Users who want the full Vicinae module (extensions/themes/etc.)
  # should add the official vicinae flake to their flake inputs.
}
