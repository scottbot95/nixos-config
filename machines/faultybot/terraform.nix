{ config, lib, ... }:
let
  hostname = "faultybot";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 501;
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
      type = "virtio";
      storage = "nvme0";
      size = "20G";
      discard = true;
    }];
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}