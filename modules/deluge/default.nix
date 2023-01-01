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
      web.enable = true;
    };

    networking.firewall.allowedTCPPorts = [ 
      6881 6891 # listen ports
      58846 # daemon port
      8112 # WebUI port
    ];
  };
}