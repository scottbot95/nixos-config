{ config, lib, pkgs, ... }:
{
  scott = {
    sops.enable = true;
    sops.envFiles.pdns = {
      vars = {
        API_KEY = "services/pdns/api_key";
      };
      requiredBy = [ "pdns.service" ];
    };
    powerdns = {
      enable = true;
      openFirewall = true;
      saltFile = "/run/secrets/services/pdns/salt";
      secretKeyFile = "/run/secrets/services/pdns/secret_key";
      secretFile = config.scott.sops.envFiles.pdns.path;
    };
  };

  sops.secrets."services/pdns/salt" = {
    mode = "0440";
    owner = config.users.users.powerdnsadmin.name;
    group = config.users.users.powerdnsadmin.group;
  };
  sops.secrets."services/pdns/secret_key" = {
    mode = "0440";
    owner = config.users.users.powerdnsadmin.name;
    group = config.users.users.powerdnsadmin.group;
  };
  sops.secrets."services/pdns/api_key" = {};

  users.users.powerdnsadmin.extraGroups = [ config.users.groups.keys.name ];

  environment.systemPackages = with pkgs; [
    pdns
  ];
}