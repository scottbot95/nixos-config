{ config, ... }:
{
  sops.secrets."gnosis/jwt" = {
    restartUnits = [ "erigon-gnosis.service" "lighthouse-beacon-gnosis.service" ];
  };

  fileSystems."/var/lib/private/erigon-gnosis" = {
    device = "/mnt/hot-storage/erigon-gnosis";
    fsType = "none";
    options = [
      "bind"
    ];
  };

  fileSystems."/var/lib/private/lighthouse-gnosis" = {
    device = "/mnt/hot-storage/lighthouse-gnosis";
    fsType = "none";
    options = [
      "bind"
    ];
  };

  services.ethereum.erigon.gnosis = {
    enable = true;
    args = {
      snapshots = true;
      port = 50505;
      chain = "gnosis";
      http = {
        port = 8745;
        vhosts = [ config.networking.fqdn ];
        api = [ "net" "web3" "eth" ];
      };
      authrpc.jwtsecret = "%d/execution-jwt";
      torrent.port = 42069;
      authrpc.vhosts = ["*"];  
      authrpc.port = 8751;
      metrics = {
        enable = true;
        addr = "0.0.0.0";
        port = 7061;
      };
      private.api.addr = "127.0.0.1:9290";
      ws.enable = true;
    };
    extraArgs = [
      "--nat" "none"
      "--prune=htcr"
      "--torrent.download.rate=96mb"
    ];
  };

  systemd.services.erigon-gnosis.serviceConfig = {
    LoadCredential = ["execution-jwt:${config.sops.secrets."gnosis/jwt".path}"];
  };

  services.ethereum.lighthouse-beacon.gnosis = {
    enable = true;
    # openFirewall = true;
    args = {
      discovery-port = 9200;
      execution-endpoint = "http://127.0.0.1:8751";
      execution-jwt = config.sops.secrets."gnosis/jwt".path;
      http.address = "0.0.0.0";
      http.port = 5252;
      metrics.address = "0.0.0.0";
      metrics.port = 5254;
      checkpoint-sync-url = "https://checkpoint.gnosischain.com";
      genesis-state-url = "https://checkpoint.gnosischain.com";
    };
    extraArgs = [
      "--gui"
      "--port" "9200"
    ];
  };

  services.ethereum.lighthouse-validator.gnosis = {
    enable = true;
    # openFirewall = true;
    args = {
      suggested-fee-recipient = "0x5610b291236E7cc44D9A1e4f051FA52506444c56";
      # http.enable = true;
      http.port = 5262;
      metrics.port = 5264;
      # http.address = "0.0.0.0";
    };
    # extraArgs = [
    #   "--unencrypted-http-transport"
    #   "--http-allow-origin" "*"
    # ];
  };

  networking.firewall.allowedTCPPorts = [
    config.services.ethereum.erigon.gnosis.args.port
    config.services.ethereum.erigon.gnosis.args.metrics.port
    config.services.ethereum.erigon.gnosis.args.torrent.port
    config.services.ethereum.lighthouse-beacon.gnosis.args.discovery-port
  ];

  networking.firewall.allowedUDPPorts = [
    config.services.ethereum.lighthouse-beacon.gnosis.args.discovery-port
    (config.services.ethereum.lighthouse-beacon.gnosis.args.discovery-port + 1)
    config.services.ethereum.erigon.gnosis.args.port
  ];
}
