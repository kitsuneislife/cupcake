{ config, pkgs, ... }:

{
  # Home-module: home/programs/terminal.nix
  # Purpose: Configure terminal emulator(s) at the user level (kitty).

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font Mono"; # "Mono" garante ícones sem ligatures
      size = 12;
    };
    settings = {
      confirm_os_window_close = 0;
      background_opacity      = "0.85";
      window_padding_width    = 10;
      enable_audio_bell       = false;

      cursor_shape              = "block";
      cursor_blink_interval     = "0.5";
      cursor_stop_blinking_after = "15.0";

      # Trail animado — rastro do cursor ao mover
      cursor_trail              = 3;      # comprimento do trail (1–10)
      cursor_trail_decay        = "0.1 0.4"; # (início fim) velocidade de fade
      cursor_trail_start_threshold = 2;   # pixels mínimos de movimento pra ativar

      foreground_color = "#f3e7ff";
    };
    # Remove o themeFile pra não sobrescrever as cores do starship.
    # Se quiser um tema base, defina as cores manualmente abaixo em `extraConfig`.
    # themeFile = "Arthur"; # ← comentado: sobrescrevia a paleta inteira

    extraConfig = ''
      # Paleta base clara pra combinar com o starship rosy
      background #1c1c1c
      foreground #ddeedd 
      cursor #e2bbef
      selection_background #4d4d4d
      color0 #3d352a
      color8 #554444
      color1 #cd5c5c
      color9 #cc5533
      color2 #86af80
      color10 #88aa22
      color3 #e8ae5b
      color11 #ffa75d
      color4 #6495ed
      color12 #87ceeb
      color5 #deb887
      color13 #996600
      color6 #b0c4de
      color14 #b0c4de
      color7 #bbaa99
      color15 #ddccbb
      selection_foreground #fb87bd
    '';
  };
}