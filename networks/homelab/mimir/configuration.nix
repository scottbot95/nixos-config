{ config, lib, nodes, ... }:
let 
in
{
  deployment.proxmox = {
    cores = 8;
    memory = 8192;
    startOnBoot = true;
    disks = [{ 
      volume = "nvme0";
      size = "50G";
      enableSSDEmulation = true;
      enableDiscard = true;
    }];
    network = [{
      bridge = "vmbr0";
      tag = 10;
    }];
  };

  scott = {
    deluge.enable = true;
    deluge.web.enable =true;
  };

  fileSystems."/var/downloads" = {
    device = "${nodes.nas.config.networking.fqdn}:/data/downloads";
    fsType = "nfs";
  };
}