{ pkgs, ethereum-nix, nixpkgs-unstable, poetry2nix, nimbus, ... }:
{
  imports = [
    ../../modules/profiles/proxmox-guest/v2.nix
    # ./holesky.nix
    # ./mainnet.nix
    ./gnosis.nix
    ethereum-nix.nixosModules.default
  ];

  fileSystems."/mnt/hot-storage" = {
    device = "/dev/disk/by-label/hot-storage";
  };
  fileSystems."/mnt/cold-storage" = {
    device = "/dev/disk/by-label/cold-storage";
  };

  nixpkgs.overlays = [
    ethereum-nix.overlays.default
    (final: prev: 
      let
        poetry2nixReal = poetry2nix.lib.mkPoetry2Nix { pkgs = import nixpkgs-unstable { inherit (pkgs) system; }; };
        stake-wise = import ./stake-wise.nix {
          pkgs = final;
        };
      in {
        lighthouse = prev.lighthouse.overrideAttrs (_: prevAttrs: {
          cargoBuildFeatures = prevAttrs.cargoBuildFeatures ++ [ "gnosis" "jemalloc" ];
        });
        nimbus = nimbus.packages.${final.system}.beacon_node.overrideAttrs (_: prevAttrs: {
          NIMFLAGS = "${prevAttrs.NIMFLAGS} -d:gnosisChainBinary -d:const_preset=gnosis";
        });
        nimbus_validator = nimbus.packages.${final.system}.validator_client.overrideAttrs (_: prevAttrs: {
          NIMFLAGS = "${prevAttrs.NIMFLAGS} -d:gnosisChainBinary -d:const_preset=gnosis";
        });
        inherit (stake-wise) operatorService;
        # erigon = prev.erigon.overrideAttrs (_: _: rec {
        #   version = "2.60.10";
        #   src = final.fetchFromGitHub {
        #     owner = "erigontech";
        #     repo = "erigon";
        #     rev = "v${version}";
        #     hash = "sha256-14s3Dfo1sqQlNZSdjByUCAsYzbv6xjPcCsBxEmoY3pU=";
        #     fetchSubmodules = true;
        #   };
        #   vendorHash = final.lib.fakeHash;
        # });
        eth-validator-watcher =
            poetry2nixReal.mkPoetryApplication {
              projectDir = pkgs.fetchFromGitHub {
                owner = "kilnfi";
                repo = "eth-validator-watcher";
                rev = "refs/tags/v1.0.0-beta.2";
                hash = "sha256-Tc/QqPYWkDzXx++VzeqVdu2fogZxLd1ZX3b6DtW2dZY=";
              };
              preferWheels = true;
              # overrides = poetry2nixReal.defaultPoetryOverrides.extend
              #   (final: prev: {
              #     pydantic-yaml = prev.pydantic-yaml.overridePythonAttrs
              #     (
              #       old: {
              #         buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
              #       }
              #     );
              #   });
            };
        # eth-validator-watcher = prev.eth-validator-watcher.overrideAttrs (_: prevAttrs: rec {
        #   name = "${prevAttrs.pname}-${version}";
        #   version = "1.0.0-beta.2";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "kilnfi";
        #     repo = prevAttrs.pname;
        #     rev = "refs/tags/v${version}";
        #     hash = "sha256-Tc/QqPYWkDzXx++VzeqVdu2fogZxLd1ZX3b6DtW2dZY=";
        #   };

        #   nativeBuildInputs = prevAttrs.nativeBuildInputs ++ (with pkgs.python3.pkgs; [
        #     setuptools
        #     pybind11
        #   ]);

        #   propagatedBuildInputs = with pkgs.python3.pkgs; [
        #     more-itertools
        #     prometheus-client
        #     pydantic
        #     requests
        #     typer
        #     slack-sdk
        #     tenacity
        #     pyyaml
        #     nixpkgs-unstable.legacyPackages.${pkgs.system}.python3.pkgs.pydantic-yaml
        #     pydantic-settings
        #     cachetools
        #   ];
        # });
      })
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  scott.sops.enable = true;

  environment.systemPackages = [
    # pkgs.lighthouse
    # pkgs.reth
    pkgs.nimbus
    pkgs.operatorService
  ];

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "24.05";
}
