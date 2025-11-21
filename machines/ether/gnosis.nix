{ config, pkgs, validator-manager-operator, ... }:
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
  feeRecipient = "0x6e4A57858a881952c0Cf4b9AF4cE551Ff4517CD5";
in
{
  imports = [
    validator-manager-operator.nixosModules.default
  ];

  sops.secrets."gnosis/jwt" = {
    restartUnits = [ "erigon-gnosis.service" "nimbus-beacon-gnosis.service" ];
  };
  sops.secrets."gnosis/validator-manager-operator" = {
    restartUnits = [ "validator-manager-operator.service" ];
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
    # package = erigon-v3;
    args = {
      port = 50505;
      chain = "gnosis";
      http = {
        port = 8745;
        vhosts = [ config.networking.fqdn ];
        api = [ "engine" "eth" "web3" "net" ];
      };
      authrpc = {
        jwtsecret = "%d/execution-jwt";
        vhosts = ["*"];  
        port = 8751;
      };
      torrent.port = 42069;
      torrent.download.rate = "96mb";
      metrics = {
        enable = true;
        addr = "0.0.0.0";
        port = 7061;
      };
      private.api.addr = "127.0.0.1:9290";
      ws.enable = true;
      prune.mode = "full";
      externalcl = true;
    };
    extraArgs = [
      "--ws.port=8746"
      "--p2p.allowed-ports=50505,50506"
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

  services.ethereum.nimbus-validator.gnosis = {
    enable = true;
    user = null;
    network = "gnosis";
    extraArgs = [
      "--non-interactive"
      "--suggested-fee-recipient=${feeRecipient}"
      "--beacon-node=http://127.0.0.1:${toString config.services.ethereum.nimbus-beacon.gnosis.args.rest.port}"
      "--data-dir=%S/nimbus-validator-gnosis"
      "--metrics"
    ];
  };

  services.validator-manager-operator = {
    enable = true;
    websocketUrl = "ws://127.0.0.1:8746";
    contracts = [ "0x94F33E6Fe24DA2e8AA9574471912f0a6E0f66cAD" ];
    walletSecret = "/run/secrets/gnosis/validator-manager-operator";
    metrics.enable = true;
    metrics.host = "0.0.0.0";
    openFirewall = true;
  };

  systemd.services.validator-manager-operator = {
    environment = {
      RUST_LOG = "validator_manager_operator=info";
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
