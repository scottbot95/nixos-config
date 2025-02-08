{ config, lib, ... }:
let
  hostname = "steam";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 601;
    domain = "prod.faultymuse.com";
    clone = "nixos-24.05.20240704.c0d0be0";
    cores = 12;
    memory = 24 * 1024;
    balloon = 4 * 1024;
    startup = "order=6";
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
      size = "200G";
      discard = true;
    };
  };
}