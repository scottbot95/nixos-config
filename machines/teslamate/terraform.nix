{ config, lib, ... }:
let
  hostname = "teslamate";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 502;
    domain = "prod.faultymuse.com";
    cores = 2;
    memory = 4096;
    startup = "order=5";
    deployment_user = "ops";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "20G";
      discard = true;
    }];
  };
}