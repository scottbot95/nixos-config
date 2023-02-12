{ config, options, lib, modulesPath, ...}:
{
  imports = [
     "${modulesPath}/profiles/qemu-guest.nix"
  ];

  config = {
    nixpkgs.system = "x86_64-linux"; # FIXME shouldn't need this but terranix proxmox module currently requires it
    nixpkgs.hostPlatform = lib.systems.examples.gnu64;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
    swapDevices = [
      { device = "/var/swapfile"; }
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

    services.qemuGuest.enable = true;

    services.openssh = {
      enable = true;
    };

    networking.domain = lib.mkDefault "lan.faultymuse.com";

    # Turn of extra docs to reduce image size
    documentation.nixos.enable = false;
  } // (if builtins.hasAttr "sops" options then {
    scott.sops.ageKeyFile = "/var/keys/age";
    sops.defaultSopsFile = ../../../secrets/homelab.yaml;
  } else {});
}