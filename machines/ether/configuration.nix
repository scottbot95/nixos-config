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
      "geth-goerli.service"
      "lighthouse-beacon.service"
    ];
  };

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";

  environment.systemPackages = [
    config.services.ethereum.lighthouse-beacon.goerli.package
  ];

  services.ethereum.geth.goerli = {
    enable = true;
    package = pkgs.geth;
    openFirewall = true;
    args = {
      network = "goerli";
      http = {
        enable = true;
        addr = "0.0.0.0";
        vhosts = [ config.networking.fqdn ];
        api = [ "net" "web3" "eth" ];
      };
      authrpc.jwtsecret = config.sops.secrets."eth/jwt".path;
    };
  };

  services.ethereum.lighthouse-beacon.goerli = {
    enable = true;
    openFirewall = true;
    args = {
      execution-jwt = config.sops.secrets."eth/jwt".path;
      http.address = "0.0.0.0";
      metrics.address = "0.0.0.0";
      checkpoint-sync-url = "https://beaconstate-goerli.chainsafe.io";
      genesis-state-url = "https://beaconstate-goerli.chainsafe.io";
    };
  };

  services.ethereum.lighthouse-validator.goerli = {
    enable = true;
    openFirewall = true;
    args = {
      suggested-fee-recipient = "0x8cD3E0e42C16CaeDA365C8089D875163b32313d1";
    };
  };


  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "23.05";
}
