{ config, ... }:
{
  sops.secrets."mainnet/jwt" = {
    restartUnits = [ "reth-mainnet.service" "lighthouse-beacon-mainnet.service" ];
  };

  fileSystems."/var/lib/private/reth-mainnet" = {
    device = "/mnt/hot-storage/reth-mainnet";
    fsType = "none";
    options = [
      "bind"
    ];
  };

  fileSystems."/var/lib/private/lighthouse-mainnet" = {
    device = "/mnt/hot-storage/lighthouse-mainnet";
    fsType = "none";
    options = [
      "bind"
    ];
  };

  services.ethereum.reth.mainnet = {
    enable = true;
    args = {
      chain = "mainnet";
      full = true;
      http = {
        enable = true;
        api = [ "net" "web3" "eth" ];
      };
      authrpc = {
        jwtsecret = config.sops.secrets."mainnet/jwt".path;
      };
      metrics = {
        enable = true;
        addr = "0.0.0.0";
      };
      log.stdout.filter = "info";
    };
    extraArgs = [
      "--ipcdisable"
    ];
  };

  services.ethereum.lighthouse-beacon.mainnet = {
    enable = true;
    openFirewall = true;
    args = {
      execution-jwt = config.sops.secrets."mainnet/jwt".path;
      http.address = "0.0.0.0";
      metrics.address = "0.0.0.0";
      checkpoint-sync-url = "https://beaconstate-mainnet.chainsafe.io";
      genesis-state-url = "https://beaconstate-mainnet.chainsafe.io";
    };
    extraArgs = [
      # "--gui"
      "--disable-deposit-contract-sync"
    ];
  };

  services.ethereum.lighthouse-validator.mainnet = {
    enable = false;
    openFirewall = true;
    args = {
      suggested-fee-recipient = "0x8cD3E0e42C16CaeDA365C8089D875163b32313d1";
      # http.enable = true;
      # http.address = "0.0.0.0";
    };
    # extraArgs = [
    #   "--unencrypted-http-transport"
    #   "--http-allow-origin" "*"
    # ];
  };

  networking.firewall.allowedTCPPorts = [
    config.services.ethereum.reth.mainnet.args.metrics.port
    9000
    30303
  ];

  networking.firewall.allowedUDPPorts = [
    9000
    9001
    30303
  ];
}
