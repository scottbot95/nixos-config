{ config, pkgs, lib, ...}:
let
  relabel_configs = [
    { source_labels = [ "__address__" ];
      target_label = "__param_target";
    }
    { source_labels = ["_param_target"];
      target_label = "instance";
    }
    { target_label = "__address__";
      replacement = "127.0.0.1:${toString config.services.prometheus.exporters.snmp.port}";
    }
  ];
in {

  services.prometheus.scrapeConfigs = [
    {
      job_name = "ups";
      inherit relabel_configs;
      metrics_path = "/snmp";
      params.module = [
        "apcups"
      ];
      static_configs = [{
        targets = [
          "ups.lan.faultymuse.com"
        ];
      }];
    }
    {
      job_name = "idrac";
      inherit relabel_configs;
      metrics_path = "/snmp";
      params.module = [
        "dell_idrac"
      ];
      static_configs = [{
        targets = [
          "idrac.lan.faultymuse.com"
        ];
      }];
    }
  ];
  
  services.prometheus.exporters.snmp = {
    enable = true;
    listenAddress = "127.0.0.1";
    configurationPath = "${./snmp.yml}";
  }; 
}