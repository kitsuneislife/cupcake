{ config, pkgs, ... }:

{
  # Module: modules/boot.nix
  # Purpose: Bootloader & kernel options moved from `configuration.nix`.
  # How to use: edit these options here; they are applied when this module is imported.

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Add kernelPackages or other boot.* options here if you need newer kernels.
}
