{ config, lib, ... }:
let
  vm_name = "public-ns";
  enable = true;
in {
  proxmox.qemu.${vm_name} = {
    inherit enable;
    # name = "ns1";
    vmid = 200;
    domain = "prod.faultymuse.com";
    cores = 2;
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
      storage = "nvme0";
      size = "20G";
      discard = true;
    }];
  };

  resource.proxmox_vm_qemu.${vm_name} = lib.mkIf enable {
    ipconfig0 = "ip=10.0.20.2/24,gw=10.0.20.1";
  };

  resource.time_sleep."${vm_name}_cloud_init_delay" = {
    triggers.${vm_name} = lib.mkForce "\${proxmox_vm_qemu.${vm_name}.ssh_host}";
  };

  module."${vm_name}_deploy_nixos" = lib.mkIf enable {
    keys.age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}