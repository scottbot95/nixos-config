{ config, lib, ... }:
let
  hostname = "odin";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 420;
    onboot = false;
    domain = "lan.faultymuse.com";
    cores = 8;
    memory = 8192;
    startup = "order=4";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 5;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "200G";
      discard = true;
    }];
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}