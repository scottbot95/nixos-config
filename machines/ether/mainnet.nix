{ config, ... }:
{
  sops.secrets."mainnet/jwt" = {
    restartUnits = [ "erigon-mainnet.service" "lighthouse-beacon-mainnet.service" ];
  };

  fileSystems."/var/lib/erigon-mainnet/snapshots" = {
    depends = [ "/mnt/cold-storage" ];
    device = "/mnt/cold-storage/mainnet/snapshots";
    fsType = "none";
    options = [
      "bind"
    ];
  };

  services.ethereum.erigon.mainnet = {
    enable = true;
    args = {
      chain = "mainnet";
      http = {
        vhosts = [ config.networking.fqdn ];
        api = [ "net" "web3" "eth" ];
      };
      authrpc.jwtsecret = "%d/execution-jwt";
      # authrpc.vhosts = ["*"];  
      ws.enable = true;
    };
    extraArgs = [
      "--nat=none"
      "--torrent.conns.perfile=25"
      "--torrent.download.rate=500mb"
    ];
  };

  systemd.services.erigon-mainnet.serviceConfig = {
    LoadCredential = ["execution-jwt:${config.sops.secrets."mainnet/jwt".path}"];
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
      "--gui"
    ];
  };

  services.ethereum.lighthouse-validator.mainnet = {
    enable = false;
    openFirewall = true;
    args = {
      suggested-fee-recipient = "0x8cD3E0e42C16CaeDA365C8089D875163b32313d1";
      http.enable = true;
      # http.address = "0.0.0.0";
    };
    # extraArgs = [
    #   "--unencrypted-http-transport"
    #   "--http-allow-origin" "*"
    # ];
  };
}
