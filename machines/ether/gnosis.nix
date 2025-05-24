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
  erigon-v3 = pkgs.buildGoModule rec {
    pname = "erigon";
    version = "3.0.3";

    src = pkgs.fetchFromGitHub {
      owner = "erigontech";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-gSgkdg7677OBOkAbsEjxX1QttuIbfve2A3luUZoZ5Ik=";
      # hash = pkgs.lib.fakeHash;
      fetchSubmodules = true;
    };

    vendorHash = "sha256-8eyC3JkRcRlFw8CyTK5w1XySur2jAeFGXkEaY/3Oq0k=";
    proxyVendor = true;

    # Silkworm's .so fails to find libgmp when linking
    tags = ["nosilkworm"];

    # Build errors in mdbx when format hardening is enabled:
    #   cc1: error: '-Wformat-security' ignored without '-Wformat' [-Werror=format-security]
    hardeningDisable = ["format"];

    ldflags = ["-extldflags \"-Wl,--allow-multiple-definition\""];
    subPackages = ["cmd/erigon" "cmd/evm" "cmd/rpcdaemon" "cmd/rlpdump"];

    meta = {
      description = "Ethereum node implementation focused on scalability and modularity";
      homepage = "https://github.com/erigontech/erigon/";
      mainProgram = "erigon";
      platforms = ["x86_64-linux"];
    };
  };
  feeRecipient = "0x6e4A57858a881952c0Cf4b9AF4cE551Ff4517CD5";
in
{
  sops.secrets."gnosis/jwt" = {
    restartUnits = [ "erigon-gnosis.service" "nimbus-beacon-gnosis.service" ];
  };

  fileSystems."/var/lib/private/erigon-gnosis" = {
    device = "/mnt/cold-storage/erigon-gnosis-v3";
    fsType = "none";
    options = [
      "bind"
    ];
  };

  fileSystems."/var/lib/private/erigon-gnosis/chaindata" = {
    device = "/mnt/hot-storage/erigon-gnosis-v3/chaindata";
    fsType = "none";
    options = [
      "bind"
    ];
  };

  fileSystems."/var/lib/private/erigon-gnosis/snapshots/domain" = {
    device = "/mnt/hot-storage/erigon-gnosis-v3/snapshots/domain";
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
    package = erigon-v3;
    args = {
      snapshots = false; # erigon v2 feature
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
      "--p2p.allowed-ports=50505,50506"
      "--nat" "none"
      # "--prune=htcr"
      "--prune.mode=archive"
      # "--prune.r.before=34778550"
      "--torrent.download.rate=96mb"
      "--externalcl"
      "--maxpeers=64"
    ];
  };

  systemd.services.erigon-gnosis.serviceConfig = {
    LoadCredential = ["execution-jwt:${config.sops.secrets."gnosis/jwt".path}"];
    SystemCallFilter = pkgs.lib.mkForce []; # TODO Limit this somewhat
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
      "--suggested-fee-recipient=${feeRecipient}"
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
            --suggested-fee-recipient=${feeRecipient} \
            --beacon-node=http://127.0.0.1:${toString config.services.ethereum.nimbus-beacon.gnosis.args.rest.port} \
            --data-dir="%S/nimbus-validator-gnosis" \
            --metrics
          '';
        in
          "${pkgs.nimbus_validator}/bin/nimbus_validator_client \\\n${scriptArgs}";

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

  systemd.services.stakewise-operator-gnosis = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    description = "Stakewise Operator Node (gnosis)";

    environment = {
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    };

    serviceConfig = {
      User = "stakewise-operator-gnosis";
      StateDirectory = "stakewise-operator-gnosis";
      ExecStart = 
        let
          scriptArgs = ''
            --vault=0x4d802ea4cb83c90b91db4acf3aa1462868405d8c \
            --consensus-endpoints=http://127.0.0.1:5052 \
            --execution-endpoints=http://127.0.0.1:8745 \
            --data-dir=%S/stakewise-operator-gnosis \
            --enable-metrics \
            --metrics-port=9100 \
            --metrics-host=0.0.0.0
          '';
        in
          "${pkgs.operatorService}/bin/operator start \\\n${scriptArgs}";
      Restart = "on-failure";

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

  # systemd.services.eth-validator-watcher-gnosis = {
  #   after = ["network.target"];
  #   wantedBy = ["multi-user.target"];
  #   description = "Ethereum Validator Watcher (gnosis)";
  #   serviceConfig = {
  #     DynamicUser = true;
  #     Restart = "on-failure";
  #     ExecStart = "${pkgs.eth-validator-watcher}/bin/eth-validator-watcher --config ${./gnosis-validators.yml}";
  #   };
  # };

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
    # config.services.ethereum.erigon.gnosis.args.port
    50505
    50506
    config.services.ethereum.erigon.gnosis.args.metrics.port
    config.services.ethereum.erigon.gnosis.args.torrent.port
    config.services.ethereum.nimbus-beacon.gnosis.args.tcp-port
    config.services.ethereum.nimbus-beacon.gnosis.args.metrics.port
    # 8000 # eth-validator-watcher metrics port
    9100 # stakewise metrics port
  ];

  networking.firewall.allowedUDPPorts = [
    config.services.ethereum.erigon.gnosis.args.port
    config.services.ethereum.nimbus-beacon.gnosis.args.udp-port
  ];
}
