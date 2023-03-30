{ config, lib, pkgs, self, ...}:
let
  rootPasswordSha2_name = "services/graylog/root_sha";
  passwordSecret_name = "services/graylog/password_secret";
  opensearch-2_5 = pkgs.opensearch.overrideAttrs (final: prev: rec {
    version = "2.5.0";
    src = pkgs.fetchurl {
      url = "https://artifacts.opensearch.org/releases/bundle/opensearch/${version}/opensearch-${version}-linux-x64.tar.gz";
      hash = "sha256-WPD5StVBb/hK+kP/1wkQQBKRQma/uaP+8ULeIFUBL1U=";
    };
  });
  graylog = self.packages.${pkgs.system}.graylog;
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # "mongodb"
    # "elasticsearch"
  ];

  sops.secrets.${rootPasswordSha2_name} = {};
  sops.secrets.${passwordSecret_name} = {};

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";
  scott.sops.envFiles.graylog = {
    vars = {
      GRAYLOG_ROOT_PASSWORD_SHA2 = rootPasswordSha2_name;
      GRAYLOG_PASSWORD_SECRET = passwordSecret_name;
    };
    requiredBy = [ "graylog.service" ];
  };


  # local mongodb only bound to 127.0.0.1 with no auth
  # services.mongodb.enable = true;
  # services.mongodb.package = pkgs.mongodb-5_0;

  # mongodb doesn't build on nix for some reason so we have to use the a container
  virtualisation.oci-containers.containers.mongo = {
    image = "mongo:6.0";
    ports = ["127.0.0.1:27017:27017"];
    volumes = [
      "/var/db/mongodb:/data/db"
    ];
  };

  systemd.services.podman-mongo.preStart = "mkdir -p /var/db/mongodb";

  services.opensearch = {
    enable = true;
    package = opensearch-2_5;
    settings ={ 
      "cluster.name" = "graylog";
      # "plugins.security.disabled" = true;
      "action.auto_create_index" = false;
    };
    extraJavaOptions = [
      "-Xms4096m"
      "-Xmx4096m"
    ];
  };

  services.graylog = {
    enable = true;
    package = graylog;
    rootPasswordSha2 = ""; # leave blank to read from env var
    passwordSecret = "";
    elasticsearchHosts = [ "http://localhost:9200" ];
    extraConfig = ''
      http_bind_address = 127.0.0.1:9000
      http_publish_uri = http://graylog.lan.faultymuse.com
    '';
  };

  systemd.services.graylog = {
    requires = [ "podman-mongo.service" "opensearch.service" ];
    after = [ "podman-mongo.service" "opensearch.service" ];
    serviceConfig = {
      EnvironmentFile = "-/run/secrets/graylog.env";
    };
  };

   services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;
    

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    virtualHosts."graylog.lan.faultymuse.com" = {
      default = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:9000";
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
  networking.firewall.allowedUDPPorts = [ 80 12201 ];

  system.stateVersion = "23.05";
}