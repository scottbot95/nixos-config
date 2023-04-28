{ config, lib, pkgs, self, ... }:
with lib;
let
  cfg = config.scott.dns-updater;
  dns-updater = self.packages.${pkgs.system}.dns-updater;
in
{
  options.scott.dns-updater = {
    enable = mkEnableOption "DNS Public IP updater";
    owner = mkOption {
      type = types.str;
      description = "Owner of tsig key config file";
      default = "root";
    };
    namesilo = {
      keyFile = mkOption {
        type = types.path;
        description = ''
          Path to file containing NameSilo API key.
          Use quotes to prevent file from being copied to the /nix/store
        '';
      };
    };
    pdns = {
      keyFile = mkOption {
        type = types.path;
        description = ''
          Path to file containing PowerDNS API key.
          Use quotes to prevent file from being copied to the /nix/store
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.timers.dns-updater = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "5m";
        Unit = "dns-updater.service";
      };
    };

    systemd.services.dns-updater = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${dns-updater}/bin/dns-updater";
        # User = "nobody";
      };
      environment = {
        TSIG_KEY_FILE = "/var/lib/dns-updater/tsig.conf";
        NAMESILO_KEY_FILE = cfg.namesilo.keyFile;
        PDNS_KEY_FILE = cfg.pdns.keyFile;
      };
    };
  };
}