{ config, lib, ... }:
let
  hostname = "nextcloud";
in {
  proxmox.qemu.${hostname} = {
    enable = false;
    vmid = 503;
    domain = "prod.faultymuse.com";
    cores = 4;
    memory = 4096;
    startup = "order=5,up=15";
    deployment_user = "ops";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [
      {
        type = "virtio";
        storage = "nvme";
        size = "20G";
        discard = true;
      }
      {
        type = "virtio";
        storage = "LTS";
        size = "2048G";
      }
    ];
  };
}