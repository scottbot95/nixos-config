{ config, lib, ...}:
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
  };

  config = mkIf cfg.enable {
    virtualisation = {
      podman.enable = true;
      oci-containers.backend = "podman";
      oci-containers.containers = {
        technitium = {
          image = "technitium/dns-server:10.0.1";
          autoStart = true;
          environment = {
            DNS_SERVER_DOMAIN = cfg.domain;
          };
          volumes = [
            "/etc/technitium:/etc/dns/config"
          ];
          extraOptions = [
            "--network=host"
          ];
        };
      };
    };
    
    system.activationScripts = {
      createTechnitiumConfig.text = "mkdir -p /etc/technitium";
    };

    networking.nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    networking.firewall.allowedTCPPorts = [ 53 5380 ];
    networking.firewall.allowedUDPPorts = [ 53 ] ++ (if cfg.dhcp then [ 67 ] else []);
  };
}