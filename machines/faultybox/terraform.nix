{ config, lib, ... }:
let
  hostname = "faultybox";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 500;
    domain = "prod.faultymuse.com";
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
      storage = "nvme";
      size = "20G";
      discard = true;
    }];
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}