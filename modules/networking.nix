{ config, pkgs, ... }:

{
  # Module: modules/networking.nix
  # Purpose: Host/network settings moved from `configuration.nix`.
  # How to use: add or change `networking.*` values here.

  networking.hostName = "nixos"; # moved from configuration.nix

  # Basic network manager
  networking.networkmanager.enable = true;

  # Optional examples (kept as comments for reference)
  # networking.wireless.enable = true;
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  # networking.firewall.enable = true;
}
