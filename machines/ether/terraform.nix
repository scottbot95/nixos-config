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

    ipconfig0 = "ip=dhcp";
    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    scsihw = "virtio-scsi-single";
    disks.ide.ide2.cloudinit = {
      storage = "local-lvm";
    };
    disks.scsi.scsi0.disk = {
      storage = "nvme";
      size = "1T";
      backup = false;
      discard = true;
      emulatessd = true;
      iothread = true;
    };
    disks.scsi.scsi1.disk = {
      storage = "LTS";
      size = "2T";
      backup = false;
      discard = true;
      emulatessd = true;
      iothread = true;
    };
    disks.virtio.virtio0.disk = {
      storage = "nvme";
      size = "20G";
      discard = true;
    };
  };
}