{ config, pkgs, ... }:

{
  # Home-module: home/desktop/theme.nix
  # Purpose: GTK/Qt/icon/wallpaper theme settings for the user.
  # How to use: add theme packages to `home.packages` and set xdg config files.
  # Example:
  #
  # home.packages = with pkgs; [ adwaita-gtk-theme papirus-icon-theme ];
  # xdg.configFile."gtk-3.0/settings.ini".text = ''[Settings]\ngtk-theme-name = Adwaita'';

  # Document-only stub — add concrete theme config when ready.
}
