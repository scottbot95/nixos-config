{ config, ... }:
{
  sops.secrets."holesky/jwt" = {
    restartUnits = [ "reth-holesky.service" "lighthouse-beacon-holesky.service" ];
  };

  fileSystems."/var/lib/private/reth-holesky" = {
    device = "/mnt/hot-storage/reth-holesky";
    fsType = "none";
    options = [
      "bind"
    ];
  };

  fileSystems."/var/lib/private/lighthouse-holesky" = {
    device = "/mnt/hot-storage/lighthouse-holesky";
    fsType = "none";
    options = [
      "bind"
    ];
  };

  services.ethereum.reth.holesky = {
    enable = true;
    args = {
      chain = "holesky";
      port = 40404;
      full = true;
      http = {
        enable = true;
        port = 8645;
        api = [ "net" "web3" "eth" ];
      };
      authrpc = {
        port = 8651;
        jwtsecret = config.sops.secrets."holesky/jwt".path;
      };
      metrics = {
        enable = true;
        addr = "0.0.0.0";
        port = 6062;
      };
      log.stdout.filter = "info";
    };
    extraArgs = [
      "--ipcdisable"
      "--discovery.port=40404"
    ];
  };

  services.ethereum.lighthouse-beacon.holesky = {
    enable = true;
    # openFirewall = true;
    args = {
      discovery-port = 9100;
      execution-endpoint = "http://127.0.0.1:8651";
      execution-jwt = config.sops.secrets."holesky/jwt".path;
      http.address = "0.0.0.0";
      http.port = 5152;
      metrics.address = "0.0.0.0";
      metrics.port = 5154;
      checkpoint-sync-url = "https://beaconstate-holesky.chainsafe.io";
      genesis-state-url = "https://beaconstate-holesky.chainsafe.io";
    };
    extraArgs = [
      "--gui"
      "--port" "9100"
    ];
  };

  services.ethereum.lighthouse-validator.holesky = {
    enable = true;
    # openFirewall = true;
    args = {
      suggested-fee-recipient = "0x8cD3E0e42C16CaeDA365C8089D875163b32313d1";
      # http.enable = true;
      http.port = 5162;
      metrics.port = 5164;
      # http.address = "0.0.0.0";
    };
    # extraArgs = [
    #   "--unencrypted-http-transport"
    #   "--http-allow-origin" "*"
    # ];
  };

  networking.firewall.allowedTCPPorts = [
    config.services.ethereum.reth.holesky.args.metrics.port
    9100
    40404
  ];

  networking.firewall.allowedUDPPorts = [
    9100
    9101
    40404
  ];
}
