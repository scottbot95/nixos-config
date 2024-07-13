{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # ethereum-nix.url = "github:nix-community/ethereum.nix";
    ethereum-nix.url = "github:scottbot95/ethereum.nix";
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
    {
      self,
      nixpkgs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./packages
        ./modules
        ./machines
      ];
      flake = {
        packages.x86_64-linux = {
          pve-minimal-iso = inputs.nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            modules = [ ./systems/pve/minimal-installer.nix ];
            format = "install-iso";
          };
        };
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        { self', pkgs, ... }:
        {
          devShells.default = import ./shell.nix {
            inherit pkgs;
            flake = self;
          };

          apps =
            let
              sops = "${pkgs.sops}/bin/sops";
              terraform = "${pkgs.opentofu}/bin/tofu";
              terranixApp =
                {
                  command,
                  name ? command,
                  config ? self'.packages.terraformConfig,
                }:
                {
                  type = "app";
                  program = toString (
                    pkgs.writers.writeBash name ''
                      set -e
                      if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                      cp ${config} config.tf.json 

                      export PATH=${pkgs.jq}/bin:$PATH
                      export TF_TOKEN_app_terraform_io=$(${sops} --extract '["tf_token"]' -d secrets/homelab.yaml)

                      ${terraform} init 
                      ${terraform} ${command} "$@"
                    ''
                  );
                };
            in
            {
              # nix run ".#apply"
              apply = terranixApp { command = "apply"; };
              # nix run ".#destroy"
              destroy = terranixApp { command = "destroy"; };
              # nix run ".#plan"
              plan = terranixApp { command = "plan"; };
            };
        };
    };
}
