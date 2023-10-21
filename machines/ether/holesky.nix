{ config, pkgs, lib, ... }:
let
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  sops.secrets."holesky/jwt" = {
    restartUnits = [ "erigon-holesky.service" "lighthouse-beacon-holesky.service" ];
  };

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";

  services.ethereum.erigon.holesky = {
    enable = true;
    args = {
      snapshots = false;
      port = 40404;
      chain = "holesky";
      http = {
        port = 8645;
        vhosts = [ config.networking.fqdn ];
        api = [ "net" "web3" "eth" ];
      };
      authrpc.jwtsecret = "%d/execution-jwt";
      torrent.port = 42169;
      authrpc.vhosts = ["*"];  
      authrpc.port = 8651;
      metrics.port = 6061;
      private.api.addr = "127.0.0.1:9190";
      ws.enable = true;
    };
    extraArgs = [
      "--nat" "none"
    ];
  };

  systemd.services.erigon-holesky.serviceConfig = {
    LoadCredential = ["execution-jwt:${config.sops.secrets."holesky/jwt".path}"];
  };

  services.ethereum.lighthouse-beacon.holesky = {
    enable = true;
    openFirewall = true;
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
    openFirewall = true;
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
}
