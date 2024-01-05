{ config, lib, ... }:
let
  hostname = "ca";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 210;
    clone = "nixos-23.11.20231202.933d7dc";
    onboot = true;
    domain = "lan.faultymuse.com";
    cores = 4;
    memory = 4096;
    startup = "order=2";
    deployment_user = "ops";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 5;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "50G";
      discard = true;
    }];
  };
}