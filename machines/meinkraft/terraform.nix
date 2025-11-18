{ config, lib, ... }:
let
  hostname = "meinkraft";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 600;
    onboot = false;
    domain = "prod.faultymuse.com";
    cores = 12;
    balloon = 12 * 1024;
    memory = 24 * 1024;
    startup = "order=5";
    deployment_user = "ops";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [{
      slot = "virtio0";
      storage = "nvme";
      size = "200G";
      discard = true;
    }];
  };

  # Disable deploying to this VM
  module."${hostname}_deploy_nixos" = lib.mkForce null;
}