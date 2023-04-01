{ config, lib, ... }:
let
  hostname = "graylog";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 200;
    domain = "lan.faultymuse.com";
    cores = 8;
    memory = 8192;
    startup = "order=2";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 5;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme0";
      size = "100G";
      discard = true;
    }];
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}