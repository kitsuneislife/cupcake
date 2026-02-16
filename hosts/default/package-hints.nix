{ }:

{
  # hosts/default/package-hints.nix
  # Purpose: persistent mapping for `eclair` to decide where to install packages.
  # Values: "home" or "system". Add entries when you want to control where a
  # specific package should be placed. `eclair` will consult this file first.
  mappings = {
    # GUI / user apps
    "firefox" = "home";
    "microsoft-edge" = "home";
    "vscode" = "home";
    "code" = "home";
    "discord" = "home";
    "slack" = "home";
    "spotify" = "home";

    # Editors / terminals / user tools
    "neovim" = "home";
    "vim" = "home";
    "tmux" = "home";
    "kitty" = "home";
    "alacritty" = "home";
    "alpine" = "home";
    "ripgrep" = "home";
    "fd" = "home";
    "bat" = "home";
    "git" = "home";

    # CLI developer tools (prefer user install by default)
    "docker" = "system";
    "docker-compose" = "system";
    "podman" = "system";
    "containerd" = "system";

    # Services / infra — system-wide
    "nginx" = "system";
    "postgresql" = "system";
    "postgres" = "system";
    "mysql" = "system";
    "mariadb" = "system";
    "redis" = "system";
    "rabbitmq" = "system";
    "cassandra" = "system";

    # Virtualization / networking — system
    "qemu" = "system";
    "libvirt" = "system";
    "virtualbox" = "system";
    "wireguard" = "system";
    "openvpn" = "system";

    # Build / CI / packaging
    "bazel" = "home";
    "go" = "home";
    "rust" = "home";

    # Misc
    "wget" = "system";
  };
    "antigravity" = "home";
    "htop" = "home";
}
