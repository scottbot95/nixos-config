{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    faultybot.url = "github:scottbot95/faultybot";
    faultybot.inputs.nixpkgs.follows = "nixpkgs";

    faultybox.url = "github:scottbot95/faultybox";
    # faultybox.inputs.nixpkgs.follows = "nixpkgs";

    terranix.url = "github:terranix/terranix";
    terranix.inputs.nixpkgs.follows = "nixpkgs";

    terranix-proxmox.url = "github:scottbot95/terranix-proxmox";
    # terranix-proxmox.url = "path:///home/scott/workplace/terranix-proxmox";
    terranix-proxmox.inputs.nixpkgs.follows = "nixpkgs";
    terranix-proxmox.inputs.terranix.follows = "terranix";
  };

  outputs = { 
    self,
    nixpkgs,
    home-manager, 
    nixos-hardware, 
    sops-nix,
    terranix,
    terranix-proxmox, 
    ... 
  }@inputs: 
  let 
    subDirs = path:
      let
        contents = builtins.readDir path;
      in builtins.filter (p: contents.${p} == "directory") (builtins.attrNames contents);
    extraArgs = { 
      inherit subDirs inputs;
      root = ./.;
      # inputs = builtins.removeAttrs inputs [ "self" ];
    };
    callPackage = nixpkgs.legacyPackages.${builtins.currentSystem}.newScope (extraArgs // { inherit extraArgs; });
    machines = import ./machines inputs;
  in nixpkgs.lib.recursiveUpdate
    {
      inherit (machines) nixosConfigurations terranixModules;

      # Output all modules in ./modules to flake. Module must be in individual
      # subdirectories and contain a default.nix which contains a standard NixOS module 
      nixosModules = let
        validModules = builtins.filter 
          (d: builtins.pathExists ./modules/${d}/default.nix)
          (subDirs ./modules);
      in (builtins.listToAttrs (builtins.map (m: { name = m; value = import ./modules/${m}; }) validModules));

      packages.x86_64-linux = {
        pve-minimal-iso = inputs.nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          modules = [
            ./systems/pve/minimal-installer.nix
          ];
          format = "install-iso";
        };
      };
    } 
    (inputs.flake-utils.lib.eachDefaultSystem
      (system:
        let 
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
              "steamcmd"
              "steam-original"
            ];
          };
          sops = "${pkgs.sops}/bin/sops";
          terraform = "${pkgs.terraform}/bin/terraform";
          terranixApp = {
            command,
            name ? command,
            config ? self.packages.${system}.terraformConfig,
          }: {
            type = "app";
            program = toString (pkgs.writers.writeBash name ''
              set -e
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${config} config.tf.json 

              export PATH=${pkgs.jq}/bin:$PATH
              export TF_TOKEN_app_terraform_io=$(${sops} --extract '["tf_token"]' -d secrets/homelab.yaml)

              ${terraform} init 
              ${terraform} ${command} "$@"
            '');
          };
        in {
          devShells.default = import ./shell.nix {
            inherit pkgs;
            flake = self;
          };

          # nix run ".#apply"
          apps.apply = terranixApp { command ="apply"; };
          # nix run ".#destroy"
          apps.destroy = terranixApp { command = "destroy"; };
          # nix run ".#plan"
          apps.plan = terranixApp { command = "plan"; };

          packages =
            (builtins.removeAttrs
              (pkgs.callPackage (import ./packages) {inherit self inputs;})
              [ "override" "overrideDerivation"]);
        }
      )
    );
}
