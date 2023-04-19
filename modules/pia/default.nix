{ config, lib, ...}:
let
  cfg = config.services.pia;
  mkServer = { name, autoStart, up, down }:
    let
      configFile = ./${name}-aes-256-cbc-udp-dns.ovpn;
    in {
      inherit autoStart up down;
      config = ''
        # import base PIA config
        config ${configFile}

        # Custom modifications
        auth-user-pass /run/secrets/pia/auth-user-pass

        # allow access to local DNS server
        route 192.168.4.2 255.255.255.255 net_gateway

        # allow access to LAN
        route 192.168.4.0 255.255.255.0 net_gateway
      '';
    };
in
with lib;
{
  options.services.pia = {
    enable = mkEnableOption "Private Internet Access OpenVPN configuration";
    servers = mkOption {
      type = with types; listOf str;
      description = mdDoc ''
        Names of PIA servers to add to OpenVPN configuration.
        Only `us3` supported at this time.
      '';
      default = [ "us3" ];
    };
    autoStart = mkOption {
      type = with types; nullOr str;
      description = "Name of OpenVPN instance to start automatically";
      default = null;
    };
    up = mkOption {
      type = types.lines;
      description = "Shell commands to execute upon establishing VPN connection";
      default = "";
    };
    down = mkOption {
      type = types.lines;
      description = "Shell commands to execute after VPN disconnected";
      default = "";
    };
  };

  config = mkIf cfg.enable {

    sops.secrets."pia/auth-user-pass" = {
      sopsFile = ./secrets.yaml;
    };

    services.openvpn.servers = listToAttrs (map (name: {
      name = "pia-${name}";
      value = mkServer {
        inherit name;
        inherit (cfg) up down;
        autoStart = (name == cfg.autoStart);
      };
    }) cfg.servers);
  };
}