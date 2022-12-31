{ config, lib, ... }:
{
  deployment.proxmox = {
    cores = 8;
    memory = 8192;
    startOnBoot = true;
    disks = [{ 
      volume = "nvme0";
      size = "20G";
      enableSSDEmulation = true;
      enableDiscard = true;
    }];
  };

  scott.faultybox.enable = true;
}