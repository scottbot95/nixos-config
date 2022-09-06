{ root, inputs, ... }@extraArgs:
{ config, lib, pkgs, ... }: {
  imports = [
    /${root}/modules/profiles/proxmox-guest.nix
    (import /${root}/modules/profiles/sops.nix extraArgs)
  ];

  sops.secrets."services/netbox/secret_key" = {
    mode = "0440";
    owner = config.users.users.netbox.name;
    group = config.users.users.netbox.group;
  };

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

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };

  services.netbox = {
    enable = true;
    secretKeyFile = "/run/secrets/services/netbox/secret_key";
  };

  # Let netbox user read keys
  users.users.netbox.extraGroups = [ config.users.groups.keys.name ];

  # Grant nginx access to netbox data dir
  users.users.nginx.extraGroups = [ config.users.groups.netbox.name ];

  services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;
    recommendedProxySettings = true;
    virtualHosts."netbox.homelab" = {
      http3 = true;
      listenAddresses = [ "0.0.0.0" ];

      locations."/static/" = {
        alias = "/var/lib/netbox/static/";
      };

      locations."/" = {
        proxyPass = "http://${config.services.netbox.listenAddress}:${builtins.toString config.services.netbox.port}";
        proxyWebsockets = true; # TODO do we actually need this?
      };
    };
  };
}