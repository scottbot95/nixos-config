{ config, options, lib, ...}:
let
  cfg = config.scott.deluge;
in
{
  options.scott.deluge = with lib; {
    enable = mkEnableOption "Deluge torrent client";
    web.enable = mkEnableOption "Deluge web client";
  };
  
  config = lib.mkIf cfg.enable {
    services.deluge = {
      enable = true;
      declarative = true;
      config = {
        daemon_port = 58846;
        allow_remote = true;
        random_port = false;
        listen_ports = [ 56881 56889 ];
        pre_allocate_storage = true;
        max_upload_speed = 20000.0;
        upnp = false;
        natpmp = false;
      };
      openFirewall = true;

      web.enable = cfg.web.enable;
    };

    services.nginx = lib.mkIf cfg.web.enable {
      enable = true;
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts.${config.networking.fqdn} = {
        locations."/" = {
          proxyPass = "http://localhost:8112";
          proxyWebsockets = true;
        };
      };
    };

    networking.firewall = {
      # allowedTCPPortRanges = [
      #   { from = 56881; to = 56889; }
      # ];
      # allowedUDPPortRanges = [
      #   { from = 56881; to = 56889; }
      # ];

      allowedTCPPorts = [
        80
        config.services.deluge.config.daemon_port
      ];
    };
  };
}