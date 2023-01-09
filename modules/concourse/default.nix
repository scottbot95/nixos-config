{ config, options, lib, pkgs, ...}:
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
    encryptionKey = mkOption {
      type = with types; nullOr str;
      description = mdDoc "Secret name to use for CONCOURSE_ENCRYPTION_KEY";
      default = null;
    };
    addLocalUser = mkOption {
      type = types.nullOr (types.submodule ({config, ...}: {
        options = {
          user = mkOption {
            type = types.str;
            default = "admin";
          };
          password = mkOption {
            type = types.str;
          };
        };
      }));
      default = null;
    };
    gitHubAuth = mkOption {
      type = types.nullOr (types.submodule ({config, ...}: {
        options = {
          clientId = mkOption {
            type = types.str;
            description = "Sops secret name to GitHub OAuth Client ID";
          };
          clientSecret = mkOption {
            type = types.str;
            description = "Sops secret name to use as GitHub OAuth Client secret";
          };
          mainTeamUsers = mkOption {
            type = with types; listOf str;
            description = "List of github users to add as main team members";
            default = [];
          };
        };
      }));
      default = null;
    };
  };

  config = mkIf cfg.enable {
    scott.sops.envFiles.concourse.vars = let
      encryptionKey = if cfg.encryptionKey != null then {
        CONCOURSE_ENCRYPTION_KEY = cfg.encryptionKey;
      } else {};
      gitHubAuth = if cfg.gitHubAuth != null then {
        CONCOURSE_GITHUB_CLIENT_ID = cfg.gitHubAuth.clientId;
        CONCOURSE_GITHUB_CLIENT_SECRET = cfg.gitHubAuth.clientSecret;
      } else {};
    in encryptionKey // gitHubAuth; 

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
        environmentFiles = [
          "/run/secrets/concourse.env"
        ];
        environment = let
          addLocalUser = if cfg.addLocalUser != null then {
            CONCOURSE_ADD_LOCAL_USER = "${cfg.addLocalUser.user}:${cfg.addLocalUser.password}";
            CONCOURSE_MAIN_TEAM_LOCAL_USER = cfg.addLocalUser.user;
          } else {};
          ghMainTeamUsers = if cfg.gitHubAuth.mainTeamUsers != [] then {
            CONCOURSE_MAIN_TEAM_GITHUB_USER = builtins.concatStringsSep "," cfg.gitHubAuth.mainTeamUsers;
          } else {};
        in {
          CONCOURSE_POSTGRES_HOST = "concourse-db";
          CONCOURSE_POSTGRES_USER = "concourse_user";
          CONCOURSE_POSTGRES_PASSWORD = "concourse_pass";
          CONCOURSE_POSTGRES_DATABASE = "concourse";
          CONCOURSE_EXTERNAL_URL = cfg.externalUrl;
          CONCOURSE_WORKER_RUNTIME = "containerd";
        } // addLocalUser // ghMainTeamUsers;
      };
    };
  };
}