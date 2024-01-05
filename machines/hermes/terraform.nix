{ config, lib, ... }:
let
  hostname = "hermes";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 520;
    domain = "dmz.faultymuse.com";
    cores = 4;
    memory = 4 * 1024;
    startup = "order=5";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 50;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "50G";
      discard = true;
    }];
  };
}