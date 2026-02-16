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

    # Global package managers used by Donut when possible
    pnpm
    pipx

    # eclair + donut: repository-local helper scripts exposed as system commands
    (pkgs.writeShellScriptBin "eclair" (builtins.readFile ../scripts/eclair.sh))
    (pkgs.writeShellScriptBin "donut" (builtins.readFile ../scripts/donut.sh))
  ] ++ (builtins.map (p: pkgs.${p}) (import ../hosts/default/user-packages.nix));

  # (Vicinae is intentionally left as a small, user-managed home fragment.)

  # Service examples (leave commented until you need them)
  # services.openssh.enable = true;
  # networking.firewall.enable = false;
}
