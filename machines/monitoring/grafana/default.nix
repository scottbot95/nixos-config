{ config, ... }:
{
  services.grafana = {
    enable = true;
    settings.server = {
      domain = config.networking.fqdn;
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

      dashboards.settings.providers = [{
        name = "default";
        folder = "homelab";
        allowUiUpdates = true;
        options.path = ./dashboards;
      }];
    };
  };
}
