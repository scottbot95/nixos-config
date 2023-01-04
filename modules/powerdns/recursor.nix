{ config, lib, pkgs, ...}:
let
  cfg = config.scott.powerdns.recursor;
in with lib; {
  options.scott.powerdns.recursor = {
    enable = mkEnableOption "PowerDNS Recursor";
    forwardZones = mkOption {
      type = types.attrsOf types.string;
      default = {};
      description = mdDoc ''
        DNS zones to be forwarded to other authoritative servers.
      '';
      example = {
        "example.com" = "127.0.0.1:5300";
      };
    };
    allowNotifyFor = mkOption {
      type = types.listOf types.string;
      default = [];
      description = mdDoc ''
        Domains to accept NOTIFY operations for.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.pdns-recursor = {
      enable = true;
      inherit (cfg) forwardZones;

      settings = {
        allow-notify-for = mkIf 
          (cfg.allowNotifyFor != [])
          (concatStringsSep "," cfg.allowNotifyFor);
      };
    };
  };
}