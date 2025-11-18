{ config, lib, ... }:
let
  hostname = "odin";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 420;
    onboot = true;
    domain = "lan.faultymuse.com";
    cores = 8;
    memory = 8192;
    startup = "order=4";
    deployment_user = "ops";
    
    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 5;
      firewall = false;
    }];

    disk = [{
      slot = "virtio0";
      storage = "nvme";
      size = "200G";
      discard = true;
    }];
  };
}