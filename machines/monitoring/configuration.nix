{ config, pkgs, lib, faultybot, nixpkgs-unstable, self, ... }:
with lib;
let
  skippedExporters = [ "unifi-poller" ]; # Skip exporters to avoid warnings
  machineConfigs = mapAttrs (_: value: value.config) self.nixosConfigurations;
  scrapeConfigs = mapAttrsToList
    (machineName: cfg:
      let
        dns = "${cfg.networking.fqdn}";
        exporters = filterAttrs
          (exporterName: exporter:
            (!(builtins.elem exporterName skippedExporters))
            && ((builtins.typeOf exporter) == "set")
            && exporter.enable
            && (exporter.listenAddress == "0.0.0.0"))
          cfg.services.prometheus.exporters;
        targets = mapAttrsToList (_: exporterCfg: "${dns}:${toString exporterCfg.port}") exporters;
      in
      mkIf (builtins.length targets > 0) {
        job_name = dns;
        static_configs = [{
          inherit targets;
        }];
      }
    )
    machineConfigs;
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
    ./grafana
    ./snmp/module.nix
    ./idrac.nix
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  # nixpkgs.pkgs = import nixpkgs-unstable {
  #   system = "x86_64-linux";
  # };

  #prometheus config
  services.prometheus = {
    enable = true;
    port = 9090;

    scrapeConfigs = scrapeConfigs ++ [
      {
        job_name = "ether.prod.faultymuse.com";
        static_configs = [{
          targets = [ 
            "ether.prod.faultymuse.com:${toString self.nixosConfigurations.ether.config.services.ethereum.lighthouse-validator.holesky.args.metrics.port}" 
            "ether.prod.faultymuse.com:${toString self.nixosConfigurations.ether.config.services.ethereum.lighthouse-beacon.holesky.args.metrics.port}" 
            # "ether.prod.faultymuse.com:${toString self.nixosConfigurations.ether.config.services.ethereum.lighthouse-beacon.mainnet.args.metrics.port}" 
          ];
        }];
      }
    ];
  };

  # loki
  services.loki = {
    enable = true;
    configuration = {

      server.http_listen_port = 9010;
      auth_enabled = false;

      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
        };
        wal = {
          enabled = true;
          dir = "/var/lib/loki/wal";
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 999999;
        chunk_retain_period = "30s";
      };

      schema_config.configs = [
        {
          from = "2023-01-01";
          store = "boltdb-shipper";
          object_store = "filesystem";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
        {
          from = "2024-07-08";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb-shipper-active";
          cache_location = "/var/lib/loki/boltdb-shipper-cache";
          cache_ttl = "24h";
        };

        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-shipper-active";
          cache_location = "/var/lib/loki/tsdb-shipper-cache";
          cache_ttl = "24h";
        };

        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };

      compactor = {
        working_directory = "/var/lib/loki";
        compactor_ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };
    };
  };

  # promtail
  services.promtail = {
    enable = true;
    configuration = {
      clients = lib.mkForce [{
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
      }];
    };
  };

  # InfluxDB
  services.influxdb = {
    enable = true;
    extraConfig = {
      udp = [{
        enabled = true;
        database = "proxmox";
        batch-size = 1000;
        batch-timeout = "1s";
      }];
    };
  };

  # TODO Not sure why we need this (we probably shouldn't)
  systemd.tmpfiles.rules = [
    "d /tmp/nginx_proxy 750 nginx nginx"
    "d /tmp/nginx_client_body 750 nginx nginx"
  ];

  # nginx reverse proxy
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    # recommendedGzipSettings = true;
    statusPage = true;

    upstreams = {
      grafana = {
        servers = {
          "127.0.0.1:${toString config.services.grafana.settings.server.http_port}" = { };
        };
      };
      loki = {
        servers = {
          "127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}" = { };
        };
      };
      promtail = {
        servers = {
          "127.0.0.1:9011" = { };
        };
      };
      influxdb = {
        servers = {
          "127.0.0.1:8086" = { };
        };
      };
    };

    virtualHosts.${config.services.grafana.settings.server.domain} = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://grafana";
        proxyWebsockets = true;
      };
      # listen = [{
      #   addr = "0.0.0.0";
      #   port = 80;
      # }];
    };

    virtualHosts.loki = {
      locations."/" = {
        proxyPass = "http://loki";
      };
      listen = [{
        addr = "0.0.0.0";
        port = 8010;
      }];
    };

    virtualHosts.promtail = {
      locations."/" = {
        proxyPass = "http://promtail";
      };
      listen = [{
        addr = "0.0.0.0";
        port = 8011;
      }];
    };

    virtualHosts.influx = {
      locations."/" = {
        proxyPass = "http://influxdb";
      };
      listen = [{
        addr = "0.0.0.0";
        port = 8020;
      }];
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 8010 8020 8011 8125 ];
  networking.firewall.allowedUDPPorts = [ 8089 ];

  system.stateVersion = "23.05";
}
