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
    memory = 4098;
    name = "teslamate";
  };

  virtualisation = {
    podman.enable = true;
    oci-containers.backend = "podman";
    oci-containers.containers = {
      teslamate = {
        image = "teslamate/teslamate:latest";
        autoStart = true;
        environment = {
          ENCRYPTION_KEY = "my-super-secrety-encryption-key";
          DATABASE_USER = "teslamate";
          DATABASE_PASS = teslamate_db_pass;
          DATABASE_NAME = "teslamate";
          DATABASE_HOST = "localhost";
          MQTT_HOST = "localhost";
        };
        ports = [ "4000:4000" ];
        extraOptions = [ "--cap-drop=all" ];
      };
      grafana = {
        image = "teslamate/grafana:latest";
        autoStart = true;
        environment = {
          DATABASE_USER = "teslamate";
          DATABASE_PASS = teslamate_db_pass;
          DATABASE_NAME = "teslamate";
          DATABASE_HOST = "teslamate";
        };
        ports = [ "3000:3000" ];
        volumes = [ "teslamate-grafana-data:/var/lib/grafana" ];
      };
      mosquitto = {
        image = "eclipse-mosquitto:2";
        autoStart = true;
        cmd = [ "mosquitto" "-c" "/mosquitto-no-auth.conf" ];
        ports = [ "127.0.0.1:1883:1883" ];
        volumes = [
          "mosquitto-conf:/mosquitto/config"
          "mosquitto-data:/mosquitto/data"
        ];
      };
    };
  };

  # Postgres DB
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "teslamate-initScript" ''
      CREATE DATABASE teslamte;
      CREATE USER telsamate with encrypted password '${teslamate_db_pass}';
      GRANT ALL PRIVILEGES ON DATABASE teslamate TO teslamate;
      ALERT USER telsamate WITH SUPERUSER;
    '';
  };

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