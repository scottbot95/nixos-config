{ config, pkgs, ... }:
let
  eth2-client-metrics-exporter = pkgs.buildGoModule rec {
    pname = "eth2-client-metrics-exporter";
    version = "e54e649b866786428baf2f05e282e4175b372ff0";
    src = pkgs.fetchFromGitHub {
      owner = "gobitfly";
      repo = pname;
      rev = version;
      hash = "sha256-+kl+Rwul4juefKJITHGwwSCQ+IVBVbmdLoTf1SjZ4b8=";
    };
    vendorHash = "sha256-o3Bn2CTHI6EZ1MUAhPAeua9q0cmCcWUjuS9sOnU20gY=";
  };
in
{
  sops.secrets."gnosis/jwt" = {
    restartUnits = [ "erigon-gnosis.service" "nimbus-beacon-gnosis.service" ];
  };

  fileSystems."/var/lib/private/erigon-gnosis" = {
    device = "/mnt/hot-storage/erigon-gnosis";
    fsType = "none";
    options = [
      "bind"
    ];
  };

  fileSystems."/var/lib/private/nimbus-beacon-gnosis" = {
    device = "/mnt/hot-storage/nimbus-beacon-gnosis";
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

  services.ethereum.nimbus-beacon.gnosis = {
    enable = true;
    args = {
      network = "gnosis";
      tcp-port = 9200;
      udp-port = 9200;

      nat = "none";
      enr-auto-update = true;

      el = ["http://127.0.0.1:8751"];

      jwt-secret = config.sops.secrets."gnosis/jwt".path;

      trusted-node-url = "https://checkpoint.gnosischain.com";
      light-client-data.import-mode = "full";

      rest.enable = true;

      metrics.enable = true;
      metrics.address = "0.0.0.0";
    };
    extraArgs = [
      "--non-interactive"
      "--suggested-fee-recipient=0x5610b291236E7cc44D9A1e4f051FA52506444c56"
    ];
  };

  systemd.services.nimbus-beacon-gnosis = {
    serviceConfig = {
      MemoryDenyWriteExecute = false;
    };
  };

  systemd.services.nimbus-validator-gnosis = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    description = "Nimbus Validator Node (gnosis)";

    serviceConfig = {
      User = "nimbus-validator-gnosis";
      StateDirectory = "nimbus-validator-gnosis";
      ExecStart = 
        let
          scriptArgs = ''
            --non-interactive \
            --suggested-fee-recipient=0x5610b291236E7cc44D9A1e4f051FA52506444c56 \
            --beacon-node=http://127.0.0.1:${toString config.services.ethereum.nimbus-beacon.gnosis.args.rest.port} \
            --data-dir="%S/nimbus-validator-gnosis" \
            --metrics
          '';
        in
          "${pkgs.nimbus}/bin/nimbus_validator_client \\\n${scriptArgs}";

      Restart = "on-failure";

      # https://www.freedesktop.org/software/systemd/man/systemd.exec.html#DynamicUser=
      # Enabling dynamic user implies other options which cannot be changed:
      #   * RemoveIPC = true
      #   * PrivateTmp = true
      #   * NoNewPrivileges = "strict"
      #   * RestrictSUIDSGID = true
      #   * ProtectSystem = "strict"
      #   * ProtectHome = "read-only"
      DynamicUser = true;

      ProtectClock = true;
      ProtectProc = "noaccess";
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      ProtectHostname = true;
      PrivateDevices = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      # Doesn't work with nimbus
      # MemoryDenyWriteExecute = true; 
      SystemCallFilter = ["@system-service" "~@privileged"];
    };
  };

  systemd.services.nimbus-exporter-gnosis = {
    wantedBy = ["multi-user.target"];
    after = ["nimbus-beacon-gnosis.service"];
    script = ''
      ${eth2-client-metrics-exporter}/bin/eth2-client-metrics-exporter \
        --server.address='https://beaconcha.in/api/v1/client/metrics?apikey=OHJ1ekQwYjdTMVpuUlFYd1lCMW43bjI2RFNheA' \
        --beaconnode.type=nimbus \
        --beaconnode.address=http://127.0.0.1:${toString config.services.ethereum.nimbus-beacon.gnosis.args.metrics.port}/metrics \
        # --validator.type=nimbus \
        # --validator.address=http://127.0.0.1:8108/metrics \
    '';
  };

  networking.firewall.allowedTCPPorts = [
    config.services.ethereum.erigon.gnosis.args.port
    config.services.ethereum.erigon.gnosis.args.metrics.port
    config.services.ethereum.erigon.gnosis.args.torrent.port
    config.services.ethereum.nimbus-beacon.gnosis.args.tcp-port
    config.services.ethereum.nimbus-beacon.gnosis.args.metrics.port
  ];

  networking.firewall.allowedUDPPorts = [
    config.services.ethereum.erigon.gnosis.args.port
    config.services.ethereum.nimbus-beacon.gnosis.args.udp-port
  ];
}
