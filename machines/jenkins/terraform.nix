{ config, lib, ... }:
let
  hostname = "jenkins";
  enable = false;
in {
  proxmox.qemu.${hostname} = {
    inherit enable;
    onboot = false;
    cores = 8;
    memory = 8192;

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "100G";
      ssd = true;
      discard = true;
    }];
  };
}