# Aggregator module for `modules/desktop`
# Purpose: allow importing `./modules/desktop` from `configuration.nix`.
# Exports a proper module (attrset) that imports child modules so the
# module loader recognizes it as a module.

{ config, pkgs, ... }:

{
  imports = [
    ./hyprland.nix
    ./sddm.nix
  ];
}
