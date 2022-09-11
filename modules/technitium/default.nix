{ config, lib, ...}:
let
  cfg = config.scott.technitium;
in
with lib; {
  options.scott.technitium = {
    enable = mkEnableOption "Technitium DNS Server";
    
  };

  config = mkIf cfg.enable {
    virtualisation = {
      podman.enable = true;
      oci-containers.backend = "podman";
      oci-containers.containers = {
        technitium = {
          image = "technitium/dns-server:8.1.4";
          autoStart = true;
          environment = {
            DNS_SERVER_DOMAIN = "hyper-dev.faultymuse.com";
          };
          ports = [
            "5380:5380/tcp"
            "53:53/udp"
            "53:53/tcp"
          ];
          volumes = [
            "/etc/technitium/config:/etc/dns/config"
          ];
          extraOptions = [
            "--network=host"
          ];
        };
      };
    };
  };
}