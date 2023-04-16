{ config, lib, ... }:
let
  hostname = "odin";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 420;
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
      storage = "nvme0";
      size = "200G";
      discard = true;
    }];
  };

  resource.proxmox_vm_qemu.${hostname} = {
    ipconfig0 = "ip=10.0.5.10/24,gw=10.0.5.1";
  };

  resource.time_sleep."${hostname}_cloud_init_delay" = {
    triggers.${hostname} = lib.mkForce "\${proxmox_vm_qemu.${hostname}.ssh_host}";
  };

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}