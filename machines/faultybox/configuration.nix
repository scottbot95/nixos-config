{ config, pkgs, lib, faultybox, ... }:
let
  certsDir = "/run/certs";
  fqdn = config.networking.fqdn;
in
{
  imports = [
    faultybox.nixosModules.faultybox
    ../../modules/profiles/proxmox-guest/v2.nix
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  networking.domain = "prod.faultymuse.com";

  services.faultybox.enable = true;
  services.faultybox.address = "127.0.0.1";

  services.nginx.enable = true;
  services.nginx.virtualHosts.${fqdn} = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.faultybox.port}";
      proxyWebsockets = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "23.05";
}