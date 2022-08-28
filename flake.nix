{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    enzimeNixpkgs.url = "github:Enzime/nixpkgs/vsce/remote-ssh-fix-patching-node";

    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # wpilib-installer = {
    #   url = "https://github.com/wpilibsuite/allwpilib/releases/download/v2022.3.1/WPILib_Linux-2022.3.1.tar.gz";
    #   flake = false;
    # };

    wpilib.url = "/home/scott/workspace/wpilib-flake";
    wpilib.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs: {
    nixosConfigurations =
      let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        wpilib-overlay = final: prev: {
          # wpilib = {
          #   # inherit (inputs.wpilib.packages.${system}) roborio-toolchain;
          #   # installer = inputs.wpilib-installer;
          # };
          wpilib = inputs.wpilib.packages.${system};
        };
        enzime-overlay = final: prev: {
          vscode-extensions = prev.vscode-extensions // {
            ms-vscode-remote = prev.vscode-extensions.ms-vscode-remote // {
              inherit (inputs.enzimeNixpkgs.legacyPackages.${system}.vscode-extensions.ms-vscode-remote) remote-ssh;
            };
          };
        };
        base = {
          inherit system;
          modules = [
            ({ ... }: {
              nixpkgs.overlays = [
                wpilib-overlay
                enzime-overlay
              ];
            })
            # Put shared modules here
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.scott = import ./modules/home.nix;
              home-manager.extraSpecialArgs = {
                extraImports = [ inputs.wpilib.nixosModules.${system}.wpilib ];
              };
            }
          ];
        };
      in
      {
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
