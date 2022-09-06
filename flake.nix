{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    enzimeNixpkgs.url = "github:Enzime/nixpkgs/vsce/remote-ssh-fix-patching-node";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixops-proxmox = {
      url = "github:scottbot95/nixops-proxmox";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    # wpilib-installer = {
    #   url = "https://github.com/wpilibsuite/allwpilib/releases/download/v2022.3.1/WPILib_Linux-2022.3.1.tar.gz";
    #   flake = false;
    # };

    # wpilib.url = "/home/scott/workspace/wpilib-flake";
    # wpilib.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, sops-nix, ... }@inputs: 
  let 
    extraArgs = { 
      root = ./.;
      inputs = builtins.removeAttrs inputs [ "self" ];
      subDirs = path:
        let
          contents = builtins.readDir path;
        in builtins.filter (p: contents.${p} == "directory") (builtins.attrNames contents);
    };
    callPackage = nixpkgs.legacyPackages.${builtins.currentSystem}.newScope (extraArgs // { inherit extraArgs; });
  in {
    inherit extraArgs;
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
      
    nixopsConfigurations = builtins.removeAttrs (callPackage ./networks {}) ["override"  "overrideDerivation"];

    packages.x86_64-linux = {
      pve-minimal-iso = inputs.nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./systems/pve/minimal-installer.nix
        ];
        format = "install-iso";
      };
    };
  } // (inputs.flake-utils.lib.eachDefaultSystem
    (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system};
        input-pkgs = builtins.mapAttrs (name: input: input.packages.${system}.default) inputs;
      in {
        devShells.default = import ./shell.nix {
          inherit pkgs;
          inputs = input-pkgs;
        };
      }
    ));
}
