{ config, lib, ... }:
let
  hostname = "boinc";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 503;
    domain = "prod.faultymuse.com";
    cores = 24;
    numa = true;
    memory = 32 * 1024;
    balloon = 8 * 1024;
    startup = "order=5";
    deployment_user = "ops";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    scsihw = "virtio-scsi-single";
    disk = [{
      type = "scsi";
      storage = "nvme";
      size = "50G";
      discard = true;
      iothread = true;
      ssd = true;
    }];
  };
}