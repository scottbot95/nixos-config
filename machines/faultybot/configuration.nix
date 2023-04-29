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

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.secrets.${discord_token_secret} = {};
  sops.secrets.${openai_key_secret} = {};

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";
  scott.sops.envFiles.faultybot = {
    vars = {
      DISCORD_TOKEN.secret = discord_token_secret;
      OPENAI_KEY.secret = openai_key_secret;
    };
    requiredBy = [ "faultybot.service" ];
  };

  services.faultybot.enable = true;
  services.faultybot.envfile = "/run/secrets/faultybot.env";

  services.prometheus.exporters.faultybot = {
    enable = true;
    openFirewall = true;
  };

  networking.domain = "prod.faultymuse.com";


  system.stateVersion = "23.05";
}