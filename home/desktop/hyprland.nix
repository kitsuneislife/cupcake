{ config, pkgs, ... }:

{
  # Home-module: home/desktop/hyprland.nix
  # Purpose: User-level Hyprland session/dotfiles (wayland config, themes).
  # How to use: import from `home.nix` and set `programs.hyprland.enable = true`.
  # Example:
  #
  # programs.hyprland.enable = true;
  # home.sessionVariables = { XDG_CURRENT_DESKTOP = "Hyprland"; };

  # Keep user session settings here (keybindings, startup programs, dotfiles).
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = "eDP-1,1920x1080@144,0x0,1";

      input = {
        kb_layout = "br";
        kb_variant = "abnt2";
      };

      env = [
        "XCURSOR_THEME,WhiteSur-cursors"
        "XCURSOR_SIZE,24"
        "GTK_THEME,WhiteSur-Dark"
      ];

      # Vicinae server is managed via a dedicated systemd user service (see `home/desktop/vicinae.nix`).
      exec = [
        "vicinae server &"
      ];

      bind = [

        "SUPER, Tab, exec, sh -c 'vicinae toggle; hyprctl dispatch movecursor 960 540'"
        "SUPER, SPACE, exec, vicinae"

        "SUPER, Q, killactive"
        "SUPER, T, exec, kitty"
        "SUPER, W, exec, microsoft-edge"
        "SUPER, C, exec, code"
        "SUPER, Esc, exit"

        # Workspace switching (SUPER + number)
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"

        # Move focused window to workspace (SUPER + SHIFT + number)
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, movetoworkspace, 9"
      ];
    };
  };
}
