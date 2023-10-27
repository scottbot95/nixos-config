{ config, pkgs, lib, ...}:
{

  services.prometheus.scrapeConfigs = [{
    job_name = "snmp";
    static_configs = [{
      targets = [
        "ups.lan.faultymuse.com"
      ];
      metrics_path = "/snmp";
      params.module = [];
      relabel_configs = [
        { source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        { source_labels = ["_param_target"];
          target_label = "instance";
        }
        { source_labels = ["__address__"];
          replacement = "127.0.0.1:${config.services.prometheus.exporters.snmp.port}";
        }
      ];
    }];
  }];
  
  services.prometheus.exporters.snmp = {
    enable = true;
    listenAddress = "127.0.0.1";
    # configurationPath = "${pkgs.prometheus-snmp-exporter.src}/snmp.yml";
    configurationPath = ./snmp.yml;
  };
}