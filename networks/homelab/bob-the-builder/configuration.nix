{config, lib, pkgs, ...}:
{
  deployment.proxmox = {
    cores = 8;
    memory = 4096;
    startOnBoot = true;
    disks = [{
      volume = "nvme0";
      size = "100G";
      enableSSDEmulation = true;
      enableDiscard = true;
    }];
    network = [{
      bridge = "vmbr0";
      tag = 5;
    }];
  };

  scott.hercules-ci.agent = {
    enable = true;
    concurrentTasks = 8;
  };
}