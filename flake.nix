{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-26.05";
    };
    nixpkgs-unstable-unfree = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
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
      mkHost = hostName: username: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit unstableUnfreePkgs; };
        modules = [
          ./hosts/${hostName}/configuration.nix
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
          {
            home-manager.sharedModules = [ nixvim.homeModules.nixvim ];
          }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit hostName username; };
            home-manager.users.${username} = import ./home.nix;
          }
        ] ++ extraModules;
      };
    in
    {
      nixosConfigurations = {
        bubu-brain = mkHost "bubu-brain" "soong" [
          { home-manager.users.soong.imports = [ ./hosts/bubu-brain/ssh-red-sun-whorl.nix ]; }
        ];
        red-sun-whorl = mkHost "red-sun-whorl" "silk" [
          nixos-hardware.nixosModules.lenovo-thinkpad-x1-nano-gen1
          {
            home-manager.users.silk.imports = [
              ./modules/programs/power-menu.nix
              ./hosts/red-sun-whorl/ssh-pas-bubu-brain.nix
            ];
            # jahlee (issue #4): pure clone of silk's desktop, isolated for
            # Hyprland exploration. home.nix takes `username` from
            # specialArgs, which home-manager.extraSpecialArgs fixes to
            # "silk" host-wide - so this overrides it per-user by calling
            # home.nix directly instead of relying on module args.
            home-manager.users.jahlee = { lib, pkgs, ... }@args:
              let
                base = import ./home.nix (args // {
                  hostName = "red-sun-whorl";
                  username = "jahlee";
                });
              in
              base // { imports = base.imports ++ [ ./modules/programs/power-menu.nix ]; };
          }
        ];
      };
    };
}

