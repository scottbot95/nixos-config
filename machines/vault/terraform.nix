{ config, lib, ... }:
let
  hostname = "vault";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 202;
    domain = "prod.faultymuse.com";
    cores = 4;
    memory = 4096;
    startup = "order=2,up=15";

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