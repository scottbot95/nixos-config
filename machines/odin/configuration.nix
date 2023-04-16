{ config, lib, self, ... }:
let 
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  scott = {
    sops.enable = true;
    deluge.enable = true;
    # deluge.web.enable = true;
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."deluge/auth_file" = {
    mode = "0660";
    owner = config.users.users.deluge.name;
    group = config.users.users.deluge.group;
    restartUnits = [ "deluged.service" ];
  };

  services.deluge = {
    config = {
      listen_interface = "10.0.5.10";
      move_completed = true;
      move_completed_path = "/mnt/downloads/deluge";
    };
    authFile = "/run/secrets/deluge/auth_file";
  };

  fileSystems."/mnt/downloads" = {
    device = "${self.nixosConfigurations.nas.config.networking.fqdn}:/downloads";
    fsType = "nfs";
  };

  networking = {
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "10.0.5.10";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.5.1";
  };

  system.stateVersion = "23.05";
}