{ config, lib, ...}:
{
  proxmox.lxc.lxc-test = {
    enable = true;
    vmid = 420;
    domain = "prod.faultymuse.com";
    # unprivileged = false;
    
    cores = 2;
    memory = 2048;
    swap = 512;

    mountpoint."/mnt/nfs_datadir_1" = {
      storage   = "LTS";
      size      = "500G";
    };

    network.eth0 = {
      bridge   = "vmbr0";
      tag      = 20;
      ip       = "dhcp";
    };
  };
}