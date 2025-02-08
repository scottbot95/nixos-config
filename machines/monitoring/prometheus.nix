{ config, lib, self, ... }:
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
  services.prometheus = {
    enable = true;
    port = 9090;

    scrapeConfigs = scrapeConfigs ++ [
      {
        job_name = "ether.prod.faultymuse.com";
        scrape_interval = "5s";
        static_configs = [{
          targets = [ 
            # "ether.prod.faultymuse.com:${toString self.nixosConfigurations.ether.config.services.ethereum.lighthouse-validator.gnosis.args.metrics.port}" 
            # "ether.prod.faultymuse.com:${toString self.nixosConfigurations.ether.config.services.ethereum.lighthouse-beacon.gnosis.args.metrics.port}" 
            "ether.prod.faultymuse.com:5054" 
            # "ether.prod.faultymuse.com:${toString self.nixosConfigurations.ether.config.services.ethereum.lighthouse-beacon.mainnet.args.metrics.port}"
          ];
        }];
      }
      {
        job_name = "stakewise-operator";
        scrape_interval = "30s";
        static_configs = [{
          targets =[
            "ether.prod.faultymuse.com:9100"
          ];
        }];        
      }
      # {
      #   job_name = "eth-validator-watcher";
      #   scrape_interval = "20s"; # 4 times per epoch. Prometheus likes 4x for reasons
      #   static_configs = [{
      #     targets = [
      #       "ether.prod.faultymuse.com:8000"
      #     ];
      #   }];
      # }
      # {
      #   job_name = "reth";
      #   static_configs = [{
      #     targets = [ 
      #       "ether.prod.faultymuse.com:${toString self.nixosConfigurations.ether.config.services.ethereum.reth.holesky.args.metrics.port}"
      #       "ether.prod.faultymuse.com:${toString self.nixosConfigurations.ether.config.services.ethereum.reth.mainnet.args.metrics.port}"
      #     ];
      #   }];
      # }
      {
        job_name = "erigon";
        scrape_interval = "10s";
        scrape_timeout = "3s";
        static_configs = [{
          targets = [
            "ether.prod.faultymuse.com:${toString self.nixosConfigurations.ether.config.services.ethereum.erigon.gnosis.args.metrics.port}"
          ];
        }];
        metrics_path = "/debug/metrics/prometheus";
      }
      {
        job_name = "unpoller";
        scrape_interval = "30s";
        scrape_timeout = "3s";
        static_configs = [{
          targets = [
            config.services.unpoller.prometheus.http_listen
          ];
        }];
      }
    ];
  };

  services.unpoller = {
    enable = true;
    unifi.defaults = {
      url = "https://192.168.4.1";
      verify_ssl = false; # TODO probably should use a known cert?
      user = "unifipoller";
      pass = "/run/secrets/unpoller/pass";
      save_sites = true;
      save_ids = false;
      save_events = false;
      save_alarms = false;
      save_dpi = false;
    };
    prometheus.http_listen = "127.0.0.1:9130";
    influxdb.disable = true;
  };
}