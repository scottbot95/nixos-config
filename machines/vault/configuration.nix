{ config, lib, ... }:
let
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."yubico/client_id" = {};
  sops.secrets."yubico/secret" = {};

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";
  scott.sops.envFiles.vaultwarden = {
    vars = {
      YUBICO_CLIENT_ID.secret = "yubico/client_id";
      YUBICO_SECRET_KEY.secret = "yubico/secret";
    };
    requiredBy = [ "vaultwarden.service" ];
  };

  networking.domain = "prod.faultymuse.com";

  services.vaultwarden = { 
    enable = true;
    environmentFile = "/run/secrets/vaultwarden.env";
    config = {
      DOMAIN = "https://${config.networking.fqdn}";
      SIGNUPS_ALLOWED = false;
    };
  };

  services.nginx = {
    enable = true;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."${config.networking.fqdn}" = {
      forceSSL = true;
      selfSigned = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:8000";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 80 443 ];

  system.stateVersion = "23.05";
}