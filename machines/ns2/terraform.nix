{ config, lib, ... }:
let
  hostname = "ns2";
  enable = false;
in {
  proxmox.qemu.${hostname} = {
    inherit enable;
    vmid = 201;
    cores = 2;
    memory = 4096;
    startup = "order=2";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 5;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme0";
      size = "20G";
      discard = true;
    }];
  };

  resource.proxmox_vm_qemu.${hostname} = lib.mkIf enable {
    ipconfig0 = "ip=10.0.5.2/24,gw=10.0.5.1";
  };

  module."${hostname}_deploy_nixos" = lib.mkIf enable {
    keys.age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}