{ config, lib, ... }:
let
  hostname = "nextcloud";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 503;
    domain = "prod.faultymuse.com";
    cores = 4;
    memory = 4096;
    startup = "order=5,up=15";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [
      {
        type = "virtio";
        storage = "nvme0";
        size = "20G";
        discard = true;
      }
      {
        type = "virtio";
        storage = "LTS";
        size = "2048G";
      }
    ];
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}