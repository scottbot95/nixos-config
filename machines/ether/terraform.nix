{ ... }:
let
  hostname = "ether";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 510;
    onboot = true;
    domain = "prod.faultymuse.com";
    clone = "nixos-24.05.20240704.c0d0be0";
    cores = 16;
    balloon = 16 * 1024;
    memory = 64 * 1024;
    startup = "order=1"; # Run this bad boy as much as possible

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    scsihw = "virtio-scsi-single";
    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "20G";
      discard = true;
    }];
  };
}