{ config, lib, faultybot, self, ... }:
with lib;
let
  skippedExporters = ["unifi-poller"]; # Skip exporters to avoid warnings
  machineConfigs = mapAttrs (_: value: value.config) self.nixosConfigurations;
  scrapeConfigs = mapAttrsToList (machineName: cfg:
    let
      dns = "${cfg.networking.hostName}.${cfg.networking.domain}";
      exporters = filterAttrs 
        (exporterName: exporter: 
          (!(builtins.elem exporterName skippedExporters))
          &&((builtins.typeOf exporter) == "set")
          && exporter.enable
          && (exporter.listenAddress == "0.0.0.0"))
        cfg.services.prometheus.exporters;
      targets = mapAttrsToList (_: exporterCfg: "${dns}:${toString exporterCfg.port}") exporters;
    in mkIf (builtins.length targets > 0) {
      job_name = dns;
      static_configs = [{
        inherit targets;
      }];
    }
  ) machineConfigs;
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
    ./grafana
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  #prometheus config
  services.prometheus = {
    enable = true;
    port = 9090;

    inherit scrapeConfigs;
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
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 999999;
        chunk_retain_period = "30s";
        max_transfer_retries = 0;
      };

      schema_config.configs = [{
        from = "2023-01-01";
        store = "boltdb-shipper";
        object_store = "filesystem";
        schema = "v11";
        index = {
          prefix = "index_";
          period = "24h";
        };
      }];

      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb-shipper-active";
          cache_location = "/var/lib/loki/boltdb-shipper-cache";
          cache_ttl = "24h";
          shared_store = "filesystem";
        };

        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
      };

      chunk_store_config = {
        max_look_back_period = "0s";
      };

      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };

      compactor = {
        working_directory = "/var/lib/loki";
        shared_store = "filesystem";
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

  # Telegraf ingestion for InfluxDB
  services.telegraf = {
    enable = true;
    extraConfig = {
      inputs = {
        # system = {}; 
        # prometheus = {
        #   urls = [
        #     "http://127.0.0.1:${toString config.services.prometheus.exporters.pve.port}/metrics" 
        #   ];
        # };

        statsd = {
          service_address = ":8125";
        };
      };
      outputs = {
        influxdb = {
          database = "homelab";
          urls = [ "http://localhost:8086" ];
        };
      };
    };
  };

  users.users.telegraf.extraGroups = [ "utmp" ];

  # nginx reverse proxy
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    statusPage = true;

    upstreams = {
      grafana = {
        servers = {
          "127.0.0.1:${toString config.services.grafana.settings.server.http_port}" = {};
        };
      };
      loki = {
        servers = {
          "127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}" = {};
        };
      };
      promtail = {
        servers = {
          "127.0.0.1:9011" = {};
        };
      };
      influxdb = {
        servers = {
          "127.0.0.1:8086" = {};
        };
      };
    };

    virtualHosts.${config.services.grafana.settings.server.domain} = {
      locations."/" = {
        proxyPass = "http://grafana";
        proxyWebsockets = true;
      };
      listen = [{
        addr = "0.0.0.0";
        port = 80;
      }];
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

  networking.firewall.allowedTCPPorts = [ 80 8010 8020 8011 8125 ];
  networking.firewall.allowedUDPPorts = [ 80 8089 ];

  system.stateVersion = "23.05";
}