{ config, lib, ... }:
let
  hostname = "ether";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 510;
    onboot = true;
    domain = "prod.faultymuse.com";
    cores = 8;
    balloon = 16 * 1024;
    memory = 96 * 1024;
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
      size = "2048G";
      discard = true;
    }];
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}