{ config, lib, ... }:
let
  hostname = "teslamate";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 502;
    domain = "prod.faultymuse.com";
    cores = 2;
    memory = 4096;
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