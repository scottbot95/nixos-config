{ config, homelab-server-manager, ... }:
let
  fqdn = config.networking.fqdn;
in
{
  imports = [
    homelab-server-manager.nixosModules.homelab-server-manager
    ../../modules/profiles/proxmox-guest/v2.nix
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  scott.sops.enable = true;
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."config" = { };
  sops.secrets."env" = { };

  networking.domain = "prod.faultymuse.com";

  services.homelab-server-manager = {
    enable = true;
    address = "127.0.0.1";
    publicUrl = "https://server-status.faultymuse.com";
    configFile = config.sops.secrets."config".path;
    envFile = config.sops.secrets."env".path;
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts.${fqdn} = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.homelab-server-manager.port}";
      proxyWebsockets = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "24.11";
}