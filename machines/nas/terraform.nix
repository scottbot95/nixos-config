{ config, lib, ... }:
{
  proxmox.lxc.nas = {
    enable = true;
    vmid = 100;
    unprivileged = false;
    startup = "order=1";

    cores = 4;
    memory = 4096;
    swap = 512;

    features = {
      nesting = true;
      mount = "nfs";
      mknod = true;
    };

    mountpoint."/mnt/nfs_datadir_1" = {
      storage = "LTS";
      size = "2T";
    };

    network.eth0 = {
      bridge = "vmbr0";
      tag = 5;
      ip = "dhcp";
    };
  };
}
