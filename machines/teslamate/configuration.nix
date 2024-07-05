{ config, pkgs, teslamate, ... }:
{
  imports = [
    ../../modules/profiles/proxmox-guest
    teslamate.nixosModules.default
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  scott = {
    sops.enable = true;
    sops.envFiles = {
      teslamate = {
        requiredBy = [ "teslamate.service" "postgresql.service" "grafana.service" ];
        vars = {
          ENCRYPTION_KEY.secret = "teslamate/encryption_key";
          RELEASE_COOKIE.secret = "teslamate/release_cookie";
          DATABASE_NAME.secret = "db/name";
          DATABASE_USER.secret = "db/user";
          DATABASE_PASS.secret = "db/pass";
        };
      };
      # db.vars = {
      #   POSTGRES_DB.secret = "db/name";
      #   POSTGRES_USER.secret = "db/user";
      #   POSTGRES_PASSWORD.secret = "db/pass";
      # };
      # grafana.vars = {
      #   DATABASE_NAME.secret = "db/name";
      #   DATABASE_USER.secret = "db/user";
      #   DATABASE_PASS.secret = "db/pass";
      #   GRAFANA_PASSWD.secret = "grafana/pass";
      #   GF_SECURITY_ADMIN_USER.secret = "grafana/user";
      #   GF_SECURITY_ADMIN_PASS.secret = "grafana/pass";
      # };
    };
  };

  sops.defaultSopsFile = ./secrets.yaml;

  sops.secrets."teslamate/encryption_key" = {};
  sops.secrets."teslamate/release_cookie" = {};
  sops.secrets."db/name" = {};
  sops.secrets."db/user" = {};
  sops.secrets."db/pass" = {};
  # sops.secrets."grafana/user" = {};
  # sops.secrets."grafana/pass" = {};

  networking.hostName = "teslamate";
  networking.domain = "prod.faultymuse.com";
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.utf8";

  environment.systemPackages = with pkgs; [
    (callPackage ./backup.nix {})
  ];

  services.teslamate = {
    enable = true;
    secretsFile = "/run/secrets/teslamate.env";
    listenAddress = "127.0.0.1";
    postgres.enable_server = true;
    grafana = {
      enable = true;
      urlPath = "/grafana";
    };
  };

  services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;
    recommendedProxySettings = true;
    virtualHosts."${config.networking.hostName}.prod.faultymuse.com" = {
      http3 = true;
      forceSSL = true;
      enableACME = true;

      locations = {
        "/grafana" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true;
        };
        "/" = {
          proxyPass = "http://127.0.0.1:4000";
          proxyWebsockets = true;
        };
      };
    };
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # For some reason this isn't enabled by default when using defaultNetwork.dns_enabled
  # networking.firewall.interfaces.podman0.allowedUDPPorts = [ 53 ];

  system.stateVersion = "23.05";
}