{ config, lib, ... }:
let
  hostname = "jenkins";
  enable = false;
in {
  proxmox.qemu.${hostname} = {
    inherit enable;
    agent = true;
    target_node = "pve";
    flake = toString ../..;
    clone = "nixos-23.05.20230127.8a828fc";
    full_clone = true;
    bios = "ovmf";
    os_type = "cloud-init";
    cores = 8;
    memory = 8192;

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [{
      type = "scsi";
      storage = "nvme0";
      size = "100G";
      ssd = true;
      discard = true;
    }];
  };
}