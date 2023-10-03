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
    (final: prev: {
      lighthouse = prev.lighthouse.overrideAttrs (final: prev: {
        # My dinky E5 v3's don't support ADX :(
        cargoBuildFeatures = [ "portable" ];
      });
    })
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."eth/jwt" = {
    restartUnits = [
      "geth-sepolia.service"
      "prysm-beacon-sepolia.service"
      "lighthouse-beacon.service"
    ];
  };

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";

  services.ethereum.geth.sepolia = {
    enable = true;
    package = pkgs.geth;
    openFirewall = true;
    args = {
      network = "sepolia";
      http = {
        enable = true;
        addr = "0.0.0.0";
        vhosts = [ config.networking.fqdn ];
        api = [ "net" "web3" "eth" ];
      };
      authrpc.jwtsecret = config.sops.secrets."eth/jwt".path;
    };
    # backup = {
    #   restic.passwordFile = "FIXME";
    # };
    # restore = {
    #   restic.passwordFile = "FIXME";
    #   snapshot = "FIXME";
    # };
  };

  services.ethereum.prysm-beacon.sepolia = {
    enable = false;
    openFirewall = true;
    args = {
      network = "sepolia";
      jwt-secret = config.sops.secrets."eth/jwt".path;
      checkpoint-sync-url = "https://checkpoint-sync.sepolia.ethpandaops.io";
      genesis-beacon-api-url = "https://checkpoint-sync.sepolia.ethpandaops.io";
    };
    extraArgs = [
      "--rpc-host=0.0.0.0"
      "--monitoring-host=0.0.0.0"
    ];
  };

  # TODO migrate to ethereum-nix whenver lighthouse is supported. Or just switch to prysm???
  services.lighthouse.network = "sepolia";
  services.lighthouse.beacon = {
    enable = true;
    openFirewall = true;
    execution.jwtPath = config.sops.secrets."eth/jwt".path;
    http.enable = true;
    http.address = "0.0.0.0";
    metrics.enable = true;
    metrics.address = "0.0.0.0";
    disableDepositContractSync = true;
    extraArgs = "--checkpoint-sync-url https://beaconstate-sepolia.chainsafe.io";
  };

  networking.firewall.allowedTCPPorts = [ 
    config.services.lighthouse.beacon.http.port 
    config.services.lighthouse.beacon.metrics.port 
  ];

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "23.05";
}
