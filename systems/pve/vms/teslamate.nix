{ config, lib, pkgs, modulesPath, ... }:
let
  teslamate_db_pass = "teslamate";
in {
  imports = [
    ../../../modules/proxmox-guest.nix
  ];

  networking.hostName = "teslamate";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.utf8";

  users.mutableUsers = true;
  users.users.scott = {
    isNormalUser = true;
    description = "Scott";
    extraGroups = ["networkmanager" "wheel" ];
    initialPassword = "password";
  };

  environment.systemPackages = with pkgs; [
    vim
  ];

  system.stateVersion = "22.05";

  proxmox.qemuConf = {
    cores = 2;
    memory = 4096;
    name = "teslamate";
  };

  # Create the docker network
  systemd.services.init-teslamate-network = {
    description = "Create the network bridge for teslamate containers";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";
    script = let
      podmanCli = "${pkgs.podman}/bin/podman";
    in ''
      # Put a true at the end to prevent getting non-zero return code, which will
      # crash the whole service.
      check=$(${podmanCli} network ls | grep "teslamate-br" || true)
      if [ -z "$check" ]; then
        ${podmanCli} network create teslamate-br
      else
        echo "teslamate-br already exists in podman"
      fi
    '';
  };

  virtualisation = {
    podman.enable = true;
    oci-containers.backend = "podman";
    oci-containers.containers = {
      teslamate = {
        image = "teslamate/teslamate:latest";
        # autoStart = true;
        environment = {
          ENCRYPTION_KEY = "my-super-secrety-encryption-key";
          DATABASE_USER = "teslamate";
          DATABASE_PASS = teslamate_db_pass;
          DATABASE_NAME = "teslamate";
          DATABASE_HOST = "database";
          MQTT_HOST = "mosquitto";
        };
        ports = [ "4000:4000" ];
        extraOptions = [ "--cap-drop=all" "--network=teslamate-br" ];
      };
      database = {
        image = "postgres:14";
        autoStart = true;
        environment = {
          POSTGRES_USER = "teslamate";
          POSTGRES_PASSWORD = teslamate_db_pass;
          POSTGRES_DB = "teslamate";
        };
        volumes = [ "teslamate-db:/var/lib/postgresql/data" ];
        extraOptions = [ "--network=teslamate-br" ];
      };
      grafana = {
        image = "teslamate/grafana:latest";
        autoStart = true;
        environment = {
          DATABASE_USER = "teslamate";
          DATABASE_PASS = teslamate_db_pass;
          DATABASE_NAME = "teslamate";
          DATABASE_HOST = "database";
        };
        ports = [ "3000:3000" ];
        volumes = [ "teslamate-grafana-data:/var/lib/grafana" ];
        extraOptions = [ "--network=teslamate-br" ];
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
        extraOptions = [ "--network=teslamate-br" ];
      };
    };
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