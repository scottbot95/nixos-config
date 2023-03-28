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

  services.SystemdJournal2Gelf = {
    enable = true;
    graylogServer = "graylog.lan.faultymuse.com:12201";
    extraOptions = "-u faultybot";
  };

  system.stateVersion = "23.05";
}