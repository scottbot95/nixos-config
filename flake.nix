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

  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, sops-nix, ... }@inputs: 
  let 
    subDirs = path:
      let
        contents = builtins.readDir path;
      in builtins.filter (p: contents.${p} == "directory") (builtins.attrNames contents);
    extraArgs = { 
      inherit subDirs;
      root = ./.;
      inputs = builtins.removeAttrs inputs [ "self" ];
    };
    callPackage = nixpkgs.legacyPackages.${builtins.currentSystem}.newScope (extraArgs // { inherit extraArgs; });
  in {
    # Output all modules in ./modules to flake. Module must be in individual
    # subdirectories and contain a default.nix which contains a function that returns a standard
    # NixOS module (!!! this means default.nix should return a function that returns a function)
    # FIXME Should find a way to inject inputs so we don't need wrapper function
    nixosModules = let
      validModules = builtins.filter 
        (d: builtins.pathExists ./modules/${d}/default.nix)
        (subDirs ./modules);
    in (builtins.listToAttrs (builtins.map (m: { name = m; value = import ./modules/${m}; }) validModules));
    
    nixosConfigurations =
      let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
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
                enzime-overlay
              ];
            })
            # Put shared modules here
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.scott = import ./modules/home.nix;
            }
          ];
        };

        machinesList = [ ./systems/raspberrytau ]; # TODO auto include everything
        machines = builtins.listToAttrs (builtins.map (m: {
          name = builtins.baseNameOf m;
          value = nixpkgs.lib.nixosSystem {
            modules = [ (m + "/configuration.nix") ];
            specialArgs = {
              inherit inputs;
            };
          };
        }) machinesList);
      in
      machines // {
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
      
    nixopsConfigurations = builtins.removeAttrs (callPackage ./networks {inherit (self) nixosModules;}) ["override"  "overrideDerivation"];

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
