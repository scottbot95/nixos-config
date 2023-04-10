{ config, lib, pkgs, self, ... }:
with lib;
let
  cfg = config.scott.dns-updater;
  dns-updater = self.packages.${pkgs.system}.dns-updater;
in
{
  options.scott.dns-updater = {
    enable = mkEnableOption "DNS Public IP updater";
  };

  config = mkIf cfg.enable {
    systemd.timers.dns-updater = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1m";
        Unit = "dns-updater.service";
      };
    };

    systemd.services.dns-updater = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${dns-updater}/bin/dns-updater";
        # User = "nobody";
      };
    };
  };
}