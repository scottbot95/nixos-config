{ config, lib, ... }:
let
  hostname = "netbox";
in
{
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 400;
    domain = "lan.faultymuse.com";
    cores = 4;
    memory = 4096;
    startup = "order=4";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 5;
      firewall = false;
    }];

    disk = [
      {
        type = "virtio";
        storage = "nvme";
        size = "20G";
        discard = true;
      }
    ];
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}
