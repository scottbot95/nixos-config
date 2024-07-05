{ pkgs, config, lib, ...}:
let
  cfg = config.scott.technitium;
in
with lib; {
  options.scott.technitium = {
    enable = mkEnableOption "Technitium DNS Server";
    domain = mkOption {
      type = types.str;
      description = "Domain name of the technitium server itself.";
      example = "ns1.lan.faultymuse.com";
    };
    # TODO can we configure DHCP server through nix?
    dhcp = mkOption {
      type = types.bool;
      description = "Open firewall port for DHCP";
      default = false;
    };
    home = mkOption {
      type = types.str;
      default = "/var/lib/technitium";
      description = lib.mdDoc "Storage path of technitium.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      podman.enable = true;
      oci-containers.backend = "podman";
      oci-containers.containers = {
        technitium = {
          image = "technitium/dns-server:12.2.1";
          # doesnt' work for some reason :(
          # user = "technitium:technitium";
          autoStart = true;
          environment = {
            DNS_SERVER_DOMAIN = cfg.domain;
          };
          volumes = [
            "${cfg.home}:/etc/dns"
          ];
          extraOptions = [
            "--network=host"
          ];
        };
      };
    };

    users.users.technitium = {
      home = "${cfg.home}";
      group = "technitium";
      isSystemUser = true;
    };
    users.groups.technitium.members = [ "technitium" ];

    systemd.tmpfiles.rules = ["d ${cfg.home} 750 technitium technitium"];

    networking.nameservers = [
      "192.168.4.2"
      "10.0.5.2"
      "1.1.1.1"
      "1.0.0.1"
    ];

    services.nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "https://127.0.0.1:53443";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 53 80 443 ];
    networking.firewall.allowedUDPPorts = [ 53 ] ++ (if cfg.dhcp then [ 67 ] else []);
  };
}