{ config, lib, pkgs, ... }:
{
  scott = {
    sops.enable = true;
    sops.envFiles.pdns = {
      vars = {
        API_KEY.secret = "pdns/api_key";
      };
      requiredBy = [ "pdns.service" ];
    };
    powerdns = {
      enable = true;
      openFirewall = true;
      saltFile = "/run/secrets/pdns/salt";
      secretKeyFile = "/run/secrets/pdns/secret_key";
      secretFile = config.scott.sops.envFiles.pdns.path;
    };
  };

  sops.secrets."pdns/salt" = {
    mode = "0440";
    owner = config.users.users.powerdnsadmin.name;
    group = config.users.users.powerdnsadmin.group;
  };
  sops.secrets."pdns/secret_key" = {
    mode = "0440";
    owner = config.users.users.powerdnsadmin.name;
    group = config.users.users.powerdnsadmin.group;
  };
  sops.secrets."pdns/api_key" = {};

  users.users.powerdnsadmin.extraGroups = [ config.users.groups.keys.name ];

  environment.systemPackages = with pkgs; [
    pdns
  ];
}