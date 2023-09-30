{ config, lib, pkgs, modulesPath, ... }:
let
  home = "/var/lib/teslamate";
  hostName = "teslamate";
  podName = "teslamate_pod";
  containerServices = builtins.map (name: "podman-${name}.service") (builtins.attrNames containers);
  containers = {
      teslamate = {
        image = "teslamate/teslamate:1.27.3";
        autoStart = true;
        environment = {
          DATABASE_HOST = "database";
          MQTT_HOST = "mosquitto";
          VIRTUAL_HOST= config.networking.fqdn;
          CHECK_ORIGIN = "true";
          TZ = config.time.timeZone;
        };
        environmentFiles = [ /run/secrets/teslamate.env ];
        ports = [ "127.0.0.1:4000:4000" ];
      };
      database = {
        image = "postgres:15";
        autoStart = true;
        environmentFiles = [ /run/secrets/db.env ];
        volumes = [ "${home}/postgresql:/var/lib/postgresql/data" ];
      };
      grafana = {
        image = "teslamate/grafana:latest";
        autoStart = true;
        environment = {
          DATABASE_HOST = "database";
          GF_AUTH_BASIC_ENABLED = "true";
          GF_AUTH_ANONYMOUS_ENABLED = "false";
          GF_SERVER_DOMAIN = config.networking.fqdn;
          GF_SERVER_ROOT_URL = "https://%(domain)s/grafana";
          GF_SERVER_SERVE_FROM_SUB_PATH = "true";
        };
        environmentFiles = [ /run/secrets/grafana.env ];
        ports = [ "127.0.0.1:3000:3000" ];
        volumes = [ "${home}/grafana:/var/lib/grafana" ];
      };
      mosquitto = {
        image = "eclipse-mosquitto:2";
        autoStart = true;
        cmd = [ "mosquitto" "-c" "/mosquitto-no-auth.conf" ];
        ports = [ "127.0.0.1:1883:1883" ];
        volumes = [
          "${home}/mosquitto/config:/mosquitto/config"
          "${home}/mosquitto/data:/mosquitto/data"
        ];
      };
    };
in {
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  scott = {
    sops.enable = true;
    sops.envFiles = {
      teslamate.vars = {
        ENCRYPTION_KEY.secret = "teslamate/encryption_key";
        DATABASE_NAME.secret = "db/name";
        DATABASE_USER.secret = "db/user";
        DATABASE_PASS.secret = "db/pass";
      };
      db.vars = {
        POSTGRES_DB.secret = "db/name";
        POSTGRES_USER.secret = "db/user";
        POSTGRES_PASSWORD.secret = "db/pass";
      };
      grafana.vars = {
        DATABASE_NAME.secret = "db/name";
        DATABASE_USER.secret = "db/user";
        DATABASE_PASS.secret = "db/pass";
        GRAFANA_PASSWD.secret = "grafana/pass";
        GF_SECURITY_ADMIN_USER.secret = "grafana/user";
        GF_SECURITY_ADMIN_PASS.secret = "grafana/pass";
      };
    };
  };

  sops.defaultSopsFile = ./secrets.yaml;

  sops.secrets."teslamate/encryption_key" = {};
  sops.secrets."db/name" = {};
  sops.secrets."db/user" = {};
  sops.secrets."db/pass" = {};
  sops.secrets."grafana/user" = {};
  sops.secrets."grafana/pass" = {};

  networking.hostName = "teslamate";
  networking.domain = "prod.faultymuse.com";
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.utf8";

  users.users.teslamate = {
    inherit home;
    isSystemUser = true;
    group = config.users.groups.teslamate.name;
  };
  users.groups.teslamate = {};

  systemd.tmpfiles.rules = [
    # "d ${home} 755 teslamate teslamate"
    # Grafana need global write cuz the container uses a custom user
    "d ${home}/grafana 777 teslamate teslamate"
    "d ${home}/postgresql 750 teslamate teslamate"
    "d ${home}/mosquitto/config 750 teslamate teslamate"
    "d ${home}/mosquitto/data 750 teslamate teslamate"
  ];

  environment.systemPackages = with pkgs; [
    (callPackage ./backup.nix {})
  ];

  # Create a target to start/stop all teslamate services
  systemd.targets.teslamate = {
    description = "Teslamate target";
    wantedBy = [ "multi-user.target" ];
    requiredBy = containerServices;
    wants = containerServices;
  };

  virtualisation = {
    podman.enable = true;
    podman.defaultNetwork.settings = {
      dns_enabled = true;
    };
    oci-containers.backend = "podman";
    oci-containers.containers = containers;
  };

  services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;
    recommendedProxySettings = true;
    virtualHosts."${config.networking.hostName}.prod.faultymuse.com" = {
      http3 = true;
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
  
  networking.firewall.allowedTCPPorts = [ 80 ];

  # For some reason this isn't enabled by default when using defaultNetwork.dns_enabled
  networking.firewall.interfaces.podman0.allowedUDPPorts = [ 53 ];

  system.stateVersion = "23.05";
}