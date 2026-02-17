{ config, pkgs, ... }:

{
  # Pacotes do tema
  home.packages = with pkgs; [
    inter
    libsForQt5.qt5ct
    qt6Packages.qt6ct
  ];

  # GTK
  gtk = {
    enable = true;
    
    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };
    
    iconTheme = {
      name = "WhiteSur";
      package = pkgs.whitesur-icon-theme;
    };
    
    cursorTheme = {
      name = "WhiteSur-cursors";
      package = pkgs.whitesur-cursors;
      size = 24;
    };
    
    font = {
      name = "Inter";
      size = 11;
    };
    
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  # Cursor
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "WhiteSur-cursors";
    package = pkgs.whitesur-cursors;
    size = 24;
  };

  # Qt
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "Fusion";
  };

  # Variáveis de ambiente
  home.sessionVariables = {
    XCURSOR_THEME = "WhiteSur-cursors";
    XCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };

  # Configuração Qt
  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    icon_theme = WhiteSur
    style = Fusion
  '';

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    icon_theme = WhiteSur
    style = Fusion
  '';
}