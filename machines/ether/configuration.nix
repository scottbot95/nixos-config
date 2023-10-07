{ config, pkgs, lib, ethereum-nix, ... }:
let
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
    ethereum-nix.nixosModules.default
  ];

  nixpkgs.overlays = [
    ethereum-nix.overlays.default
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."eth/jwt" = {
    restartUnits = [
      "geth-holesky.service"
      "prysm-beacon-holesky.service"
      "lighthouse-beacon.service"
    ];
  };

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";

  services.ethereum.geth.holesky = {
    enable = true;
    package = pkgs.geth;
    openFirewall = true;
    args = {
      network = "holesky";
      http = {
        enable = true;
        addr = "0.0.0.0";
        vhosts = [ config.networking.fqdn ];
        api = [ "net" "web3" "eth" ];
      };
      authrpc.jwtsecret = config.sops.secrets."eth/jwt".path;
    };
  };

  services.ethereum.prysm-beacon.holesky = {
    enable = false;
    openFirewall = true;
    args = {
      network = "holesky";
      jwt-secret = config.sops.secrets."eth/jwt".path;
      checkpoint-sync-url = "https://beaconstate-holesky.chainsafe.io";
      genesis-beacon-api-url = "https://beaconstate-holesky.chainsafe.io";
    };
    extraArgs = [
      "--rpc-host=0.0.0.0"
      "--monitoring-host=0.0.0.0"
    ];
  };

  services.ethereum.lighthouse-beacon.holesky = {
    enable = true;
    openFirewall = true;
    args = {
      execution-jwt = config.sops.secrets."eth/jwt".path;
      http-address = "0.0.0.0";
      metrics-address = "0.0.0.0";
      disable-deposit-contract-sync = true;
      checkpoint-sync-url = "https://beaconstate-holesky.chainsafe.io";
      genesis-state-url = "https://beaconstate-holesky.chainsafe.io";
    };
  };


  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "23.05";
}
