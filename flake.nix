{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-24.11";
    };
    nixpkgs-unstable-unfree = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable-unfree, home-manager, ... }: {
    nixosConfigurations = {
      bubu-brain = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          unstableUnfreePkgs = import nixpkgs-unstable-unfree {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.soong = import ./home.nix;
          }
        ];
      };
    };
  };
}

