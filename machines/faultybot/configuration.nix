{ config, pkgs, lib, faultybot, ... }:
let
  discord_token_secret = "discord_token";
  openai_key_secret = "openai_key";
  github_token = "github_token";
  github_confirmation_channel = "github_confirmation_channel";
in
{
  imports = [
    faultybot.nixosModules.faultybot
    ../../modules/profiles/proxmox-guest/v2.nix
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.${discord_token_secret} = { };
  sops.secrets.${openai_key_secret} = { };
  sops.secrets.${github_token} = { };
  sops.secrets.${github_confirmation_channel} = { };

  scott.sops.enable = true;
  scott.sops.envFiles.faultybot = {
    vars = {
      DISCORD__TOKEN.secret = discord_token_secret;
      OPENAI__KEY.secret = openai_key_secret;
      GITHUB__TOKEN.secret = github_token;
      GITHUB__CONFIRMATION_CHANNEL.secret = github_confirmation_channel;
    };
    requiredBy = [ "faultybot.service" ];
  };

  services.faultybot = {
    enable = true;
    envfile = "/run/secrets/faultybot.env";
    settings = {
      database.url = "postgresql:///faultybot?host=/var/run/postgresql";
      github = {
        owner = "scottbot95";
        repo = "faultybot";
      };
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    # Need an init script since you can't grant schema under a specific database with
    # services.postgresql.ensureUsers
    initialScript = pkgs.writeText "faultybot-initScript" ''
      CREATE DATABASE faultybot;
      CREATE USER "faultybot";
      GRANT ALL PRIVILEGES ON DATABASE faultybot TO "faultybot";
      \c faultybot
      GRANT ALL ON SCHEMA public TO "faultybot";
    '';
  };

  systemd.services.faultybot = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  services.prometheus.exporters.faultybot = {
    enable = true;
    openFirewall = true;
  };

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "23.05";
}
