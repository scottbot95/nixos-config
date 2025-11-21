{ pkgs, ethereum-nix, nixpkgs-unstable, poetry2nix, ... }:
{
  imports = [
    ../../modules/profiles/proxmox-guest/v2.nix
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
        inherit (stake-wise) operatorService;
        erigon = prev.erigon.overrideAttrs (_: _: rec {
          version = "3.2.2";
          src = final.fetchFromGitHub {
            owner = "erigontech";
            repo = "erigon";
            rev = "v${version}";
            hash = "sha256-RMid7yfCP3RsiGTbD/+cT9HinEd2+tjlav/70YNRGu0=";
            fetchSubmodules = true;
          };
          vendorHash = "sha256-dAAZTFs4KwjRvQp+RRlLqlfxsD7rxqk0Q7TvcIy0Tgg=";
        });
        eth-validator-watcher =
            poetry2nixReal.mkPoetryApplication {
              projectDir = pkgs.fetchFromGitHub {
                owner = "kilnfi";
                repo = "eth-validator-watcher";
                rev = "refs/tags/v1.0.0-beta.2";
                hash = "sha256-Tc/QqPYWkDzXx++VzeqVdu2fogZxLd1ZX3b6DtW2dZY=";
              };
              preferWheels = true;
            };
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
