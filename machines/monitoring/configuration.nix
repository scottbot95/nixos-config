{ config, lib, faultybot, ... }:
let
  /*
  pve-exporter:
    user: monitoring@pve
    token_name: pve-exporter
    token_value: 87e38c6b-6d8f-402c-9c84-49a128ba5d8b
    verify_ssl: false
   */
  PVE_USER = "pve_exporter/user";
  PVE_TOKEN_NAME = "pve_exporter/token_name";
  PVE_TOKEN_VALUE = "pve_exporter/token_value";
  PVE_VERIFY_SSL = "pve_exporter/verify_ssl";
  INFLUX_TOKEN = "monitoring/influx_token";
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  # sops.secrets.${PVE_USER} = {};
  # sops.secrets.${PVE_TOKEN_NAME} = {};
  # sops.secrets.${PVE_TOKEN_VALUE} = {};
  # sops.secrets.${PVE_VERIFY_SSL} = {};
  # sops.secrets.${INFLUX_TOKEN} = {};

  # scott.sops.enable = true;
  # scott.sops.ageKeyFile = "/var/keys/age";
  # scott.sops.envFiles.pve-exporter = {
  #   vars = {
  #     inherit PVE_USER PVE_TOKEN_NAME PVE_TOKEN_VALUE PVE_VERIFY_SSL;
  #   };
  #   requiredBy = [ ];
  # };
  # scott.sops.envFiles.telegraf = {
  #   vars = {
  #     inherit INFLUX_TOKEN;
  #   };
  #   requiredBy = [ "telegraf.service" ];
  # };

  # grafana config
  services.grafana = {
    enable = true;
    settings.server = {
      domain = "monitoring.lan.faultymuse.com";
      http_port = 2342;
      http_addr = "127.0.0.1";
      root_url = "http://%(domain)s";
    };

    provision = {
      datasources.settings.datasources = [
        # {
        #   name = "Prometheus";
        #   type = "prometheus";
        #   url = "http://localhost:${toString config.services.prometheus.port}";
        # }
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
    };
  };

  #prometheus config
  # services.prometheus = {
  #   enable = true;
  #   port = 9001;

  #   exporters = {
  #     node = {
  #       enable = true;
  #       enabledCollectors = [ "systemd" ];
  #       port = 9002;
  #     };
      
  #     nginx = {
  #       enable = true;
  #       port = 9003;
  #       listenAddress = "127.0.0.1";
  #     };

  #     nginxlog = {
  #       enable = true;
  #       port = 9004;
  #       listenAddress = "127.0.0.1";
  #       group = "nginx"; # Use nginx user group to exporter has read-only access to logs
  #       settings = {
  #         namespaces = [{
  #           name = "grafana";
  #           source.files = ["/var/log/nginx/access.log"];
  #         }];
  #       };
  #     };

  #     pve = {
  #       enable = true;
  #       listenAddress = "127.0.0.1";
  #       port = 9005;
  #       environmentFile = "/run/secrets/pve-exporter.env";
  #     };
  #   };

  #   scrapeConfigs = [
  #     {
  #       job_name = "monitoring.lan.faultymuse.com";
  #       static_configs = [{
  #         targets = [
  #           "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" 
  #           "127.0.0.1:${toString config.services.prometheus.exporters.nginx.port}" 
  #           "127.0.0.1:${toString config.services.prometheus.exporters.nginxlog.port}" 
  #         ];
  #       }];
  #     }
  #     {
  #       job_name = "faultybot.prod.faultymuse.com";
  #       static_configs = [{
  #         targets = [ "faultybot.prod.faultymuse.com:9000" ];
  #       }];
  #     }
  #     {
  #       job_name = "pve";
  #       static_configs = [{
  #         targets = [ "pve.faultymuse.com" ];
  #       }];
  #       metrics_path = "/pve";
  #       params.module = [ "default" ];
  #       relabel_configs = [
  #         { 
  #           source_labels = ["__address__"];
  #           target_label = "__param_target";
  #         }
  #         { 
  #           source_labels = ["__param_target"];
  #           target_label = "instance";
  #         }
  #         { 
  #           target_label = "__address__";
  #           replacement = "127.0.0.1:${toString config.services.prometheus.exporters.pve.port}";
  #         }
  #       ];
  #     }
  #   ];
  # };

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
      agent = {
        
      };
      inputs = {
        system = {}; 
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

  networking.firewall.allowedTCPPorts = [ 80 8010 8020 8011 ];
  networking.firewall.allowedUDPPorts = [ 80 8089 ];

  system.stateVersion = "23.05";
}