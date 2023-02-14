{ config, lib, ... }:
let
  hostname = "ns2";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
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
      type = "scsi";
      storage = "nvme0";
      size = "20G";
      ssd = true;
      discard = true;
    }];
  };

  resource.proxmox_vm_qemu.${hostname}.ipconfig0 = "ip=10.0.5.2/24,gw=10.0.5.1";

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}