{ config, lib, pkgs, modulesPath, ... }:
let
  hostName = "teslamate";
  podName = "teslamate_pod";
  containerServices = builtins.map (name: "podman-${name}.service") (builtins.attrNames containers);
  containers = {
      teslamate = {
        image = "teslamate/teslamate:1.27";
        autoStart = true;
        environment = {
          DATABASE_HOST = "database";
          MQTT_HOST = "mosquitto";
          VIRTUAL_HOST= config.networking.fqdn;
          CHECK_ORIGIN = "true";
          TZ = config.time.timeZone;
        };
        environmentFiles = [ /run/secrets/teslamate.env ];
        # ports = [ "127.0.0.1:4000:4000" ];
        extraOptions = [ "--cap-drop=all" "--pod=${podName}" ];
      };
      database = {
        image = "postgres:14";
        autoStart = true;
        environmentFiles = [ /run/secrets/db.env ];
        volumes = [ "teslamate-db:/var/lib/postgresql/data" ];
        extraOptions = [ "--pod=${podName}" ];
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
        # ports = [ "127.0.0.1:3000:3000" ];
        volumes = [ "teslamate-grafana-data:/var/lib/grafana" ];
        extraOptions = [ "--pod=${podName}" ];
      };
      mosquitto = {
        image = "eclipse-mosquitto:2";
        autoStart = true;
        cmd = [ "mosquitto" "-c" "/mosquitto-no-auth.conf" ];
        # ports = [ "127.0.0.1:1883:1883" ];
        volumes = [
          "mosquitto-conf:/mosquitto/config"
          "mosquitto-data:/mosquitto/data"
        ];
        extraOptions = [ "--pod=${podName}" ];
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
        ENCRYPTION_KEY = "teslamate/encryption_key";
        DATABASE_NAME = "db/name";
        DATABASE_USER = "db/user";
        DATABASE_PASS = "db/pass";
      };
      db.vars = {
        POSTGRES_DB = "db/name";
        POSTGRES_USER = "db/user";
        POSTGRES_PASSWORD = "db/pass";
      };
      grafana.vars = {
        DATABASE_NAME = "db/name";
        DATABASE_USER = "db/user";
        DATABASE_PASS = "db/pass";
        GRAFANA_PASSWD = "grafana/pass";
        GF_SECURITY_ADMIN_USER = "grafana/user";
        GF_SECURITY_ADMIN_PASS = "grafana/pass";
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
  networking.domain = "faultymuse.com";
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.utf8";

  system.stateVersion = "23.05";

  # Create a target to start/stop all teslamate services
  systemd.targets.teslamate = {
    description = "Teslamate target";
    wantedBy = [ "multi-user.target" ];
    requiredBy = containerServices ++ [ "podman-create-pod-teslamate.service" ];
    wants = containerServices;
  };

  # Create the docker network
  systemd.services.podman-create-pod-teslamate = {
    description = "Create the pod for teslamate containers";
    wantedBy = containerServices;

    serviceConfig.Type = "oneshot";
    script = let
      podmanCli = "${pkgs.podman}/bin/podman";
    in ''
      ${podmanCli} pod exists ${podName} || ${podmanCli} pod create --name ${podName} -p 127.0.0.1:3000:3000 -p 127.0.0.1:4000:4000
    '';
  };

  virtualisation = {
    podman.enable = true;
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
}