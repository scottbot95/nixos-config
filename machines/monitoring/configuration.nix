{ config, lib, faultybot, ... }:
let
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

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
          url = "http://localhost:9001";
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
    };

    scrapeConfigs = [
      {
        job_name = "monitoring.lan.faultymuse.com";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };


  # nginx reverse proxy
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
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