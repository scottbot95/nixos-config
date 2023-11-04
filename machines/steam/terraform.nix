{ config, lib, ... }:
let
  hostname = "steam";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 601;
    domain = "prod.faultymuse.com";
    cores = 12;
    memory = 24 * 1024;
    balloon = 4 * 1024;
    startup = "order=6";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
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