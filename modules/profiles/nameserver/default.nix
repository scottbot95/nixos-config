{ config, lib, pkgs, ... }:
{
  scott = {
    sops.enable = true;
    powerdns = {
      enable = true;
      saltFile = "/run/secrets/services/pdns/salt";
      secretKeyFile = "/run/secrets/services/pdns/secret_key";
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

  users.users.powerdnsadmin.extraGroups = [ config.users.groups.keys.name ];

  environment.systemPackages = with pkgs; [
    pdns
  ];

  system.stateVersion = "23.05";
}