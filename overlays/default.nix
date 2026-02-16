self: super:

{
  # Overlay: overlays/default.nix
  # Purpose: place custom package overrides and small helper packages here.
  # How to use: add this overlay to your flake or nixpkgs config, for example:
  #
  # nixpkgs.overlays = [ (import ./overlays/default.nix) ];
  #
  # Example custom package (small helper script):
  meu-script = super.writeShellScriptBin "meu-script" ''
    echo "Hello from custom overlay script!"
  '';
}
