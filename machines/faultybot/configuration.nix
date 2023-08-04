{ config, pkgs, lib, faultybot, ... }:
let
  discord_token_secret = "discord_token";
  openai_key_secret = "openai_key";
in
{
  imports = [
    faultybot.nixosModules.faultybot
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.${discord_token_secret} = { };
  sops.secrets.${openai_key_secret} = { };

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";
  scott.sops.envFiles.faultybot = {
    vars = {
      DISCORD_TOKEN.secret = discord_token_secret;
      OPENAI_KEY.secret = openai_key_secret;
    };
    requiredBy = [ "faultybot.service" ];
  };

  services.faultybot = {
    enable = true;
    envfile = "/run/secrets/faultybot.env";
    settings = {
      database.url = "postgresql:///faultybot?host=/var/run/postgresql";
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
