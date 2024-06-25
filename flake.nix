{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    ethereum-nix.url = "github:nix-community/ethereum.nix";
    # ethereum-nix.url = "github:scottbot95/ethereum.nix/lighthouse-service";
    # ethereum-nix.url = "path:///home/scott/workplace/ethereum.nix";
    # ethereum-nix.inputs.nixpkgs.follows = "nixpkgs";

    faultybot.url = "github:scottbot95/faultybot";
    faultybot.inputs.nixpkgs.follows = "nixpkgs";

    faultybox.url = "github:scottbot95/faultybox";
    # faultybox.inputs.nixpkgs.follows = "nixpkgs";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    # nix-minecraft.url = "path:///home/scott/workplace/nix-minecraft";

    # steam-servers.url = "github:scottbot95/nix-steam-servers";
    steam-servers.url = "path:///home/scott/workplace/nix-steam-servers";
    steam-servers.inputs.nixpkgs.follows = "nixpkgs";

    teslamate.url = "github:teslamate-org/teslamate";
    teslamate.inputs.nixpkgs.follows = "nixpkgs-unstable";

    terranix.url = "github:terranix/terranix";
    terranix.inputs.nixpkgs.follows = "nixpkgs";

    terranix-proxmox.url = "github:scottbot95/terranix-proxmox";
    # terranix-proxmox.url = "path:///home/scott/workplace/terranix-proxmox";
    terranix-proxmox.inputs.nixpkgs.follows = "nixpkgs";
    terranix-proxmox.inputs.terranix.follows = "terranix";

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nil.url = "github:oxalica/nil";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , nixos-hardware
    , sops-nix
    , terranix
    , terranix-proxmox
    , ...
    }@inputs:
    let
      subDirs = path:
        let
          contents = builtins.readDir path;
        in
        builtins.filter (p: contents.${p} == "directory") (builtins.attrNames contents);
      machines = import ./machines inputs;
    in
    nixpkgs.lib.recursiveUpdate
      {
        inherit (machines) nixosConfigurations vms;

        # Output all modules in ./modules to flake. Module must be in individual
        # subdirectories and contain a default.nix which contains a standard NixOS module 
        nixosModules =
          let
            validModules = builtins.filter
              (d: builtins.pathExists ./modules/${d}/default.nix)
              (subDirs ./modules);
          in
          (builtins.listToAttrs (builtins.map (m: { name = m; value = import ./modules/${m}; }) validModules));

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
          };
          sops = "${pkgs.sops}/bin/sops";
          terraform = "${pkgs.opentofu}/bin/tofu";
          terranixApp =
            { command
            , name ? command
            , config ? self.packages.${system}.terraformConfig
            ,
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
        in
        {
          devShells.default = import ./shell.nix {
            inherit pkgs;
            flake = self;
          };

          # nix run ".#apply"
          apps.apply = terranixApp { command = "apply"; };
          # nix run ".#destroy"
          apps.destroy = terranixApp { command = "destroy"; };
          # nix run ".#plan"
          apps.plan = terranixApp { command = "plan"; };

          packages =
            (builtins.removeAttrs
              (pkgs.callPackage (import ./packages) { inherit self inputs; })
              [ "override" "overrideDerivation" ]);
        }
        )
      );
}
