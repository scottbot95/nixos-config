{ config, lib, ... }:
let
  hostname = "meinkraft";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 600;
    onboot = true;
    domain = "prod.faultymuse.com";
    cores = 12;
    balloon = 12 * 1024;
    memory = 24 * 1024;
    startup = "order=5";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "200G";
      discard = true;
    }];
  };
}