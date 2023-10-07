{ config, lib, self, pkgs, ...}:
with lib;
let 
  cfg = config.services.prometheus.exporters.minecraft;
in {
  options.services.prometheus.exporters.minecraft = {
    enable = mkEnableOption "Minecraft Prometheus Exporter";

    environmentFile = mkOption {
      type = types.str;
      example = "/run/secrets/minecraft-exporter.env";
      description = "Path to an environment file containing at least MC_RCON_PASSWORD";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open `port` TCP";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to listen on";
    };

    port = mkOption {
      type = types.port;
      default = 9150;
      description = "Port to listen on";
    };

    rconHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host to try to connect to RCON";
    };

    rconPort = mkOption {
      type = types.port;
      default = 25575;
      description = "Port to use when trying to connect to RCON";
    };

    worldPath = mkOption {
      type = types.str;
      example = "/var/lib/minecraft/world";
      description = "Path to Minecraft world directory";
    };

    modServerStats = mkOption {
      type = with types; nullOr (enum [ "forge" "papermc" ]);
      default = null;
      description = "Whether to collect stats emitted by a particular modding framework";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.prometheus-minecraft-exporter = let 
      # TODO put this shit in a config file
      scriptArgs = concatStringsSep " \\\n" (
        [ 
          "--mc.rcon-address=${cfg.rconHost}:${toString cfg.rconPort}"
          "--mc.world=${cfg.worldPath}"
        ]
        ++ (optionals (cfg.modServerStats != null) ["--mc.mod-server-stats=${cfg.modServerStats}"])
      );
    in {
      description = "Minecraft Exporter";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        DynamicUser = true;
        Type = "simple";
        ExecStart = "${self.packages.${pkgs.system}.minecraft-prometheus-exporter}/bin/minecraft-exporter \\\n${scriptArgs}";
        EnvironmentFile = cfg.environmentFile;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}