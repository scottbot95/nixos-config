{ config, lib, pkgs, modulesPath, ...}:
let
in {
  imports = [ 
    "${modulesPath}/profiles/qemu-guest.nix"
    ../../modules/profiles/proxmox-guest 
  ];

  proxmox.qemuConf = {
    cores = 4;
    memory = 4096;
    bios = "ovmf";
    virtio0 = "local-lvm:vm-9999-disk-0";
  };
  proxmox.qemuExtraConf = {
    ide2 = "local-lvm:vm-9999-cloudinit,media=cdrom";
    template = 1;
  };

  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;

  system.stateVersion = "23.05";
}