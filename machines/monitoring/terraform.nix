{ config, lib, ... }:
let
  hostname = "monitoring";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 201;
    domain = "lan.faultymuse.com";
    cores = 8;
    balloon = 8 * 1024;
    memory = 16 * 1024;
    startup = "order=2";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 5;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "100G";
      discard = true;
    }];
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}