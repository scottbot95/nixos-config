{ sops-nix }:
{ config, lib, pkgs, ... }:
let

in {
  imports = [
    ../../../modules/profiles/proxmox-guest.nix
    (import ../../../modules/profiles/sops.nix { inherit sops-nix; })
  ];

  deployment.proxmox = {
    cores = 2;
    memory = 4096;
    startOnBoot = true;
    disks = [{
      volume = "nvme0";
      size = "100G";
      enableSSDEmulation = true;
      enableDiscard = true;
    }];
  };

  networking.hostName = "netbox";
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.utf8";

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    ensureUsers = [{
      name = "netbox";
      ensurePermissions = {
        "DATABASE netbox" = "ALL PRIVILEGES";
      };
    }];
    ensureDatabases = [ "netbox" ];
  };

  services.redis = {
    servers.netbox = {
      enable = true;
    };
  };
}