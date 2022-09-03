{ secrets }:
{ config, lib, pkgs, modulesPath, ... }:
let
  podName = "teslamate_pod";
  containerServices = builtins.map (name: "podman-${name}.service") (builtins.attrNames containers);
  containers = {
      teslamate = {
        image = "teslamate/teslamate:latest";
        # autoStart = true;
        environment = {
          ENCRYPTION_KEY = secrets.database.encryption_key;
          DATABASE_USER = secrets.database.user;
          DATABASE_PASS = secrets.database.password;
          DATABASE_NAME = "teslamate";
          DATABASE_HOST = "database";
          MQTT_HOST = "mosquitto";
        };
        # ports = [ "4000:4000" ];
        extraOptions = [ "--cap-drop=all" "--pod=${podName}" ];
      };
      database = {
        image = "postgres:14";
        autoStart = true;
        environment = {
          POSTGRES_USER = secrets.database.user;
          POSTGRES_PASSWORD = secrets.database.password;
          POSTGRES_DB = "teslamate";
        };
        volumes = [ "teslamate-db:/var/lib/postgresql/data" ];
        extraOptions = [ "--pod=${podName}" ];
      };
      grafana = {
        image = "teslamate/grafana:latest";
        autoStart = true;
        environment = {
          DATABASE_USER = secrets.database.user;
          DATABASE_PASS = secrets.database.password;
          DATABASE_NAME = "teslamate";
          DATABASE_HOST = "database";
        };
        # ports = [ "3000:3000" ];
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
    ../../../modules/proxmox-guest.nix
  ];

  networking.hostName = "teslamate";
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.utf8";

  deployment.proxmox = {
    cores = 2;
    memory = 4096;
    startOnBoot = true;
    disks = [{
      volume = "nvme0";
      size = "100G";
      enableSSDEmulation = true;
      enableDiscard = true;
    }];
  };

  environment.systemPackages = with pkgs; [
    vim
  ];

  system.stateVersion = "22.05";

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
      ${podmanCli} pod exists ${podName} || ${podmanCli} pod create --name ${podName} -p 4000:4000 -p 3000:3000
    '';
  };

  virtualisation = {
    podman.enable = true;
    oci-containers.backend = "podman";
    oci-containers.containers = containers;
  };

  # Postgres DB
  # services.postgresql = {
  #   enable = true;
  #   package = pkgs.postgresql_14;
  #   authentication = pkgs.lib.mkOverride 10 ''
  #     local all all trust
  #     host all all 127.0.0.1/32 trust
  #     host all all ::1/128 trust
  #   '';
  #   initialScript = pkgs.writeText "teslamate-initScript" ''
  #     CREATE DATABASE teslamate;
  #     CREATE USER teslamate WITH ENCRYPTED PASSWORD '${teslamate_db_pass}';
  #     GRANT ALL PRIVILEGES ON DATABASE teslamate TO teslamate;
  #     ALTER USER teslamate WITH SUPERUSER;
  #   '';
  # };

  # # Grafana
  # services.grafana = {
  #   enable = true;
  #   # Remove if manual plugins must be installed
  #   declarativePlugins = with pkgs.grafanaPlugins; let
  #     pr0ps-trackmap-panel = grafanaPlugin rec {
  #       pname = "pr0ps-trackmap-panel";
  #       version = "2.1.2";
  #       zipHash = "sha256-KMEM0ZrGCp3PA22bSyG+q/IgKWCkWRKX9NyS3g3kkds=";
  #     };
  #     natel-plotly-panel = grafanaPlugin rec {
  #       pname = "natel-plotly-panel";
  #       version = "0.0.7";
  #       zipHash = "sha256-gYqzO0KhQhtWH05E8M0ZzRpWdn05UgRbgEKk2li9Rw4=";
  #     };
  #   in [
  #     pr0ps-trackmap-panel
  #     natel-plotly-panel
  #   ];
  # };

  # # Mosquitto
  # services.mosquitto = {
  #   enable = true;
  # }
}