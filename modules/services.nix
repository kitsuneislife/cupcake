{ config, pkgs, ... }:

{
  # Module: modules/services.nix
  # Purpose: System-wide services and basic system settings (time, locale, pkgs).
  # How to use: edit `time.*`, `i18n.*`, `environment.*` and service flags here.

  # Time & locale
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "pt_BR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Console / keyboard
  console.keyMap = "br-abnt2";
  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  # Package policy
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    kitty

    # Version managers required by `donut`
    fnm
    pyenv
    rustup
    
    # Luaver (packaged manually as it is not in nixpkgs)
    (pkgs.stdenv.mkDerivation {
      pname = "luaver";
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = "DhavalKapil";
        repo = "luaver";
        rev = "master";
        sha256 = "0s0pfr5mlmyc18l34n8w8h24bi8i9jj0zajygldsa5jgkwjxzggz";
      };
      installPhase = ''
        mkdir -p $out/bin $out/share/luaver
        cp -r * $out/share/luaver
        # Create a wrapper script that sources luaver internally
        # Note: luaver needs to function as a sourced script for 'use', so this binary is mostly for 'install'/'uninstall'
        # For 'use', users should source $out/share/luaver/luaver in their shell RC.
        
        makeWrapper ${pkgs.bash}/bin/bash $out/bin/luaver \
          --add-flags "$out/share/luaver/luaver" \
          --prefix PATH : ${lib.makeBinPath [ pkgs.curl pkgs.gnutar pkgs.gzip pkgs.gnumake pkgs.gcc pkgs.readline pkgs.ncurses pkgs.openssl ]}
      '';
      nativeBuildInputs = [ pkgs.makeWrapper ];
    })

    # Global package managers used by Donut when possible
    pnpm
    pipx
    luarocks

    # eclair + donut: repository-local helper scripts exposed as system commands
    (pkgs.writeShellScriptBin "eclair" (builtins.readFile ../scripts/eclair.sh))
    (pkgs.writeShellScriptBin "donut" (builtins.readFile ../scripts/donut.sh))
  ] ++ (let
    userPkgs = if builtins.pathExists ../hosts/default/user-packages.nix then import ../hosts/default/user-packages.nix else import ../hosts/default/user-packages.nix.template;
  in builtins.map (p: pkgs.${p}) userPkgs);

  # Ensure luaver source script is available for interactive shells to enable 'luaver use'
  programs.bash.interactiveShellInit = ''
    if command -v luaver >/dev/null 2>&1; then
      # Locate the actual script if possible, or just rely on the user manually sourcing if preferred.
      # Since we wrapped it, 'luaver' command runs a subshell. To affect current shell, we need sourcing.
      # We find where it is installed in system path.
      LUA_VER_SCRIPT=$(readlink -f $(which luaver) | sed 's|/bin/luaver|/share/luaver/luaver|')
      # Fallback to standard Nix OS path if readlink fails or suggests store path directly
      if [[ -f "$LUA_VER_SCRIPT" ]]; then
        alias luaver="source $LUA_VER_SCRIPT"
      fi
    fi
  '';

  # (Vicinae is intentionally left as a small, user-managed home fragment.)

  # Service examples (leave commented until you need them)
  # services.openssh.enable = true;
  # networking.firewall.enable = false;
}
