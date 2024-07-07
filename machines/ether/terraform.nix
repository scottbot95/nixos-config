{ config, lib, ... }:
let
  hostname = "ether";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 510;
    onboot = false;
    domain = "prod.faultymuse.com";
    cores = 12;
    balloon = 16 * 1024;
    memory = 96 * 1024;
    startup = "order=1"; # Run this bad boy as much as possible

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "4096G";
      discard = true;
    }];
  };

  # Disable deploying to this VM
  module."${hostname}_deploy_nixos" = lib.mkForce null;
}