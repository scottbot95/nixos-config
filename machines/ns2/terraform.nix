{ config, lib, ... }:
let
  hostname = "ns2";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 203;
    cores = 2;
    memory = 4096;
    startup = "order=2";

    domain = "lan.faultymuse.com";
    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 5;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "20G";
      discard = true;
    }];
  };

  resource.proxmox_vm_qemu.${hostname} = {
    ipconfig0 = "ip=10.0.5.2/24,gw=10.0.5.1";
  };

  resource.time_sleep."${hostname}_cloud_init_delay" = {
    triggers.${hostname} = lib.mkForce "\${proxmox_vm_qemu.${hostname}.ssh_host}";
  };

  module."${hostname}_deploy_nixos" = {
    keys.age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}