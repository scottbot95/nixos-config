{ config, lib, pkgs, ...}:
let
  cfg = config.scott.concourse;
in with lib; {
  options.scott.concourse = {
    enable = mkEnableOption "Concourse CI/CD service";
    port = mkOption {
      type = types.ints.unsigned;
      description = "Port to bind Concourse Web UI to";
      default = 8080;
    };
    externalUrl = mkOption {
      type = types.str;
      description = "External URL to bind";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      defaultNetwork.dnsname.enable = true;
    };
    virtualisation.oci-containers.backend = "podman";
    virtualisation.oci-containers.containers = {
      concourse-db = {
        image = "postgres";
        autoStart = true;
        environment = {
          POSTGRES_DB = "concourse";
          POSTGRES_PASSWORD = "concourse_pass";
          POSTGRES_USER = "concourse_user";
          PGDATA = "/database";
        };
        volumes = [ "pgdata:/database" ];
      };

      concourse = {
        image = "concourse/concourse";
        cmd = [ "quickstart" ];
        extraOptions = [ "--privileged" ];
        ports = [ "${toString cfg.port}:8080" ];
        environment = {
          CONCOURSE_POSTGRES_HOST = "concourse-db";
          CONCOURSE_POSTGRES_USER = "concourse_user";
          CONCOURSE_POSTGRES_PASSWORD = "concourse_pass";
          CONCOURSE_POSTGRES_DATABASE = "concourse";
          CONCOURSE_EXTERNAL_URL = cfg.externalUrl;
          CONCOURSE_ADD_LOCAL_USER = "admin:password";
          CONCOURSE_MAIN_TEAM_LOCAL_USER = "admin";
          CONCOURSE_WORKER_RUNTIME = "containerd";
        };
      };
    };
  };
}