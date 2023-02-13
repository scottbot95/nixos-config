{ config, lib, ... }:
let
  hostname = "faultybox";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    agent = true;
    vmid = 500;
    target_node = "pve";
    flake = toString ../..;
    clone = "nixos-23.05.20230127.8a828fc";
    full_clone = true;
    bios = "ovmf";
    os_type = "cloud-init";
    cores = 8;
    memory = 8192;
    onboot = true;
    startup = "order=5";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
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

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}