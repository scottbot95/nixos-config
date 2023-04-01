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
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  sops.secrets.${PVE_USER} = {};
  sops.secrets.${PVE_TOKEN_NAME} = {};
  sops.secrets.${PVE_TOKEN_VALUE} = {};
  sops.secrets.${PVE_VERIFY_SSL} = {};

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";
  scott.sops.envFiles.pve-exporter = {
    vars = {
      inherit PVE_USER PVE_TOKEN_NAME PVE_TOKEN_VALUE PVE_VERIFY_SSL;
    };
    requiredBy = [ "prometheus-pve-exporter.service" ];
  };

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
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString config.services.prometheus.port}";
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
    };
  };

  #prometheus config
  services.prometheus = {
    enable = true;
    port = 9001;

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
      
      nginx = {
        enable = true;
        port = 9003;
        listenAddress = "127.0.0.1";
      };

      nginxlog = {
        enable = true;
        port = 9004;
        listenAddress = "127.0.0.1";
        group = "nginx"; # Use nginx user group to exporter has read-only access to logs
        settings = {
          namespaces = [{
            name = "grafana";
            source.files = ["/var/log/nginx/access.log"];
          }];
        };
      };

      pve = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9005;
        environmentFile = "/run/secrets/pve-exporter.env";
      };
    };

    scrapeConfigs = [
      {
        job_name = "monitoring.lan.faultymuse.com";
        static_configs = [{
          targets = [
            "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" 
            "127.0.0.1:${toString config.services.prometheus.exporters.nginx.port}" 
            "127.0.0.1:${toString config.services.prometheus.exporters.nginxlog.port}" 
          ];
        }];
      }
      {
        job_name = "pve";
        static_configs = [{
          targets = [ "pve.faultymuse.com" ];
        }];
        metrics_path = "/pve";
        params.module = [ "default" ];
        relabel_configs = [
          { 
            source_labels = ["__address__"];
            target_label = "__param_target";
          }
          { 
            source_labels = ["__param_target"];
            target_label = "instance";
          }
          { 
            target_label = "__address__";
            replacement = "127.0.0.1:${toString config.services.prometheus.exporters.pve.port}";
          }
        ];
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
      server = {
        http_listen_port = 9011;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
      }];
      scrape_configs = [{
        job_name = "journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = "pihole";
          };
        };
        relabel_configs = [{
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }];
      }];
    };
  };


  # nginx reverse proxy
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    statusPage = true;
    virtualHosts.${config.services.grafana.settings.server.domain} = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
  networking.firewall.allowedUDPPorts = [ 80 ];

  system.stateVersion = "23.05";
}