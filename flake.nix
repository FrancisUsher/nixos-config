{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-24.11";
    };
    nixpkgs-unstable-unfree = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable-unfree, ... }: {
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
        ];
      };
    };
  };
}

