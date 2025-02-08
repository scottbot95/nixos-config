{ config, lib, ... }:
let
  hostname = "nextcloud";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 504;
    domain = "prod.faultymuse.com";
    clone = "nixos-24.05.20240704.c0d0be0";
    cores = 4;
    memory = 4096;
    startup = "order=5,up=15";
    deployment_user = "ops";

    ipconfig0 = "ip=dhcp";
    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disks.ide.ide2.cloudinit = {
      storage = "local-lvm";
    };
    disks.virtio.virtio0.disk = {
      storage = "nvme";
      size = "20G";
      discard = true;
    };
    disks.virtio.virtio1.disk = {
      storage = "LTS";
      size = "2T";
    };
  };
}