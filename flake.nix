{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let
    localCfg = if builtins.pathExists ./local.nix then import ./local.nix else { username = "lukas"; };
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };  # <-- ADICIONE ESTA LINHA
            # Backup existing files that would be clobbered by Home Manager
            home-manager.backupFileExtension = ".bak";
            # Use the computed `localCfg` (from outputs let-binding) to set the home-manager user
            home-manager.users = { "${localCfg.username}" = import ./home.nix; };
          }
        ];
      };

      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hosts/desktop.nix
        ];
      };

      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hosts/laptop.nix
        ];
      };
    };
  };
}
