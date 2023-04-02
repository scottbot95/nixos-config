{ config, lib, faultybot, ... }:
let
  discord_token_secret = "services/faultybot/discord_token";
  openai_key_secret = "services/faultybot/openai_key";
in
{
  imports = [
    faultybot.nixosModules.faultybot
    ../../modules/profiles/proxmox-guest
  ];

  sops.secrets.${discord_token_secret} = {};
  sops.secrets.${openai_key_secret} = {};

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";
  scott.sops.envFiles.faultybot = {
    vars = {
      DISCORD_TOKEN = discord_token_secret;
      OPENAI_KEY = openai_key_secret;
    };
    requiredBy = [ "faultybot.service" ];
  };

  services.faultybot.enable = true;
  services.faultybot.envfile = "/run/secrets/faultybot.env";
  services.faultybot.metrics.enable = true;

  # promtail
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9001;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://monitoring.lan.faultymuse.com:8010/loki/api/v1/push";
      }];
      scrape_configs = [{
        job_name = "journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = "faultybot";
          };
        };
        relabel_configs = [{
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }];
      }];
    };
  };

  system.stateVersion = "23.05";
}