{ config, lib, ... }:
let
  hostname = "faultybox";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 500;
    cores = 8;
    memory = 8192;
    startup = "order=5";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [{
      type = "scsi";
      storage = "nvme0";
      size = "20G";
      ssd = true;
      discard = true;
    }];
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}