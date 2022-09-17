{ config, lib, pkgs, modulesPath, ... }:
let
  podName = "teslamate_pod";
  containerServices = builtins.map (name: "podman-${name}.service") (builtins.attrNames containers);
  containers = {
      teslamate = {
        image = "teslamate/teslamate:latest";
        autoStart = true;
        environment = {
          DATABASE_NAME = "teslamate";
          DATABASE_HOST = "database";
          MQTT_HOST = "mosquitto";
        };
        environmentFiles = [ /run/secrets/.env ];
        # ports = [ "4000:4000" ];
        extraOptions = [ "--cap-drop=all" "--pod=${podName}" ];
      };
      database = {
        image = "postgres:14";
        autoStart = true;
        environment = {
          POSTGRES_DB = "teslamate";
        };
        environmentFiles = [ /run/secrets/.env ];
        volumes = [ "teslamate-db:/var/lib/postgresql/data" ];
        extraOptions = [ "--pod=${podName}" ];
      };
      grafana = {
        image = "teslamate/grafana:latest";
        autoStart = true;
        environment = {
          DATABASE_NAME = "teslamate";
          DATABASE_HOST = "database";
        };
        environmentFiles = [ /run/secrets/.env ];
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
  scott = {
    sops.enable = true;
    proxmoxGuest.enable = true;
  };

  sops.secrets."services/teslamate/database/user" = {};
  sops.secrets."services/teslamate/database/password" = {};
  sops.secrets."services/teslamate/encryption_key" = {};

  networking.hostName = "teslamate";
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.utf8";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  systemd.services.sops-make-env = {
    description = "Collect sops secrets into an env file";
    wantedBy = [ "teslamate.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
user=$(cat /run/secrets/services/teslamate/database/user)
password=$(cat /run/secrets/services/teslamate/database/password)
encryption_key=$(cat /run/secrets/services/teslamate/encryption_key)
cat << EOF > /run/secrets/.env
DATABASE_USER=$user
POSTGRES_USER=$user
DATABASE_PASS=$password
POSTGRES_PASSWORD=$password
ENCRYPTION_KEY=$encryption_key
EOF
    '';
  };

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

  services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;
    recommendedProxySettings = true;
    virtualHosts."${config.networking.hostName}.lan.faultymuse.com" = {
      http3 = true;
      locations = {
        # "/grafana" = {
        #   proxyPass = "http://127.0.0.1:3000";
        #   proxyWebsockets = true;
        # };
        "/" = {
          proxyPass = "http://127.0.0.1:4000";
          proxyWebsockets = true;
        };
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 3000 ];
}