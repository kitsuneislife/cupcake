# QuickShell — top bar shell for Hyprland

Resumo
- `quickshell` é um toolkit para construir shells/top‑bars sobre Wayland (QtQuick).
- Nesta configuração o QuickShell é instalado como `home.package` e é iniciado automaticamente como a `shell` do sistema (autostart).  

Comportamento configurado
- Autostart: habilitado por padrão via `systemd --user` + `autostart` desktop entry.
- Não adicionamos um keybind — o QuickShell inicia automaticamente e fornece a barra/shell principal.

Como funciona (rápido)
- O arquivo `home/desktop/quickshell.nix` escreve o unit `~/.config/systemd/user/quickshell.service`, o `autostart` desktop entry e um `~/.config/quickshell/config.json` mínimo.
- O package `quickshell` é obtido de `nixpkgs` (se disponível).

Notas
- Se preferir outra shell/topbar (Vicinae), remova `quickshell` de `home.programs.packages.nix` e ajuste `home/desktop/*` conforme necessário.
