{ lib, self, ... }:
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
    ];
  };
}