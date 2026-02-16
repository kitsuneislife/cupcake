{ config, pkgs, ... }:

{
  # Home-module: home/desktop/vicinae.nix
  # Purpose: run Vicinae as a user systemd service and provide minimal settings.

  # ensure vicinae package is available for the user (redundant-safe)
  home.packages = with pkgs; [ vicinae ];

  # systemd user service to run the vicinae server (auto-start)
  systemd.user.services.vicinae = {
    description = "Vicinae launcher server (user)";
    script = false;
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.vicinae}/bin/vicinae server";
      Restart = "on-failure";
      Environment = "USE_LAYER_SHELL=1";
    };
  };

  # Basic (optional) settings region — kept small and safe
  # Users who want the full Vicinae module (extensions/themes/etc.)
  # should add the official vicinae flake to their flake inputs.
}
