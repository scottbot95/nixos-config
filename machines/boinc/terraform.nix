{ config, lib, ... }:
let
  hostname = "boinc";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 503;
    domain = "prod.faultymuse.com";
    cores = 24;
    numa = true;
    memory = 32 * 1024;
    balloon = 8 * 1024;
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
      size = "50G";
      discard = true;
    }];
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}