{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wpilib-installer = {
      url = "https://github.com/wpilibsuite/allwpilib/releases/download/v2022.2.1/WPILib_Linux-2022.2.1.tar.gz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, wpilib-installer, ...}@inputs: {
    nixosConfigurations = let
      wpilib-overlay = final: prev: {
        wpilib.installer = wpilib-installer;
      };
      base = rec {
        system = "x86_64-linux";
        modules = [
          ({...}: { nixpkgs.overlays = [ wpilib-overlay ]; })
          # Put shared modules here
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.scott = import ./modules/home.nix;
          }
        ];
      };
    in {
      marvinIso = nixpkgs.lib.nixosSystem {
        inherit (base) system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

          # Provide an initial copy of te NixOS channel so that we
          # don't need to run `nix-channel --update` first.
          "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
        ];
      };

      marvin = nixpkgs.lib.nixosSystem {
        inherit (base) system;
        modules = base.modules ++ [
          nixos-hardware.nixosModules.lenovo-thinkpad-t480
          ./systems/marvin/configuration.nix
        ];
      };
    };
  };
}