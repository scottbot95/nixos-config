{ config, pkgs, ... }:
let
  lighthouse-metrics = pkgs.fetchFromGitHub {
    owner = "sigp";
    repo = "lighthouse-metrics";
    rev = "71054d58b340a5f01f0da0cc24f900035247388f";
    hash = "sha256-00RosQhsWFgZm8gTioe57+aixbupDQqqiqhjDPOtjCA=";
  };
in
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

      dashboards.settings.providers = [
        {
          name = "default";
          folder = "homelab";
          allowUiUpdates = true;
          options.path = ./dashboards;
        }
        {
          name = "lighthouse";
          folder = "lighthouse";
          allowUiUpdates = true;
          options.path = "${lighthouse-metrics}/dashboards";
        }
      ];
    };
  };
}
