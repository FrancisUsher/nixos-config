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
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      # release-24.11 predates the starship target (added in 25.05+), and
      # trying 25.05 with nixpkgs.follows pinned back to nixos-24.11 hit
      # unrelated fcitx5-vs-home-manager-24.11 breakage - so staying on the
      # matching release branch for now. Revisit starship theming once the
      # flake's nixpkgs/home-manager/stylix get bumped together (see
      # TODO.md's "Nix release bump" item).
      url = "github:nix-community/stylix/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable-unfree, home-manager, nixos-hardware, nixvim, stylix, ... }:
    let
      system = "x86_64-linux";
      unstableUnfreePkgs = import nixpkgs-unstable-unfree {
        inherit system;
        config.allowUnfree = true;
      };
      mkHost = hostName: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit unstableUnfreePkgs; };
        modules = [
          ./hosts/${hostName}/configuration.nix
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
          {
            home-manager.sharedModules = [ nixvim.homeManagerModules.nixvim ];
          }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.soong = import ./home.nix;
          }
        ] ++ extraModules;
      };
    in
    {
      nixosConfigurations = {
        bubu-brain = mkHost "bubu-brain" [ ];
        x1nano = mkHost "x1nano" [ nixos-hardware.nixosModules.lenovo-thinkpad-x1-nano-gen1 ];
      };
    };
}

