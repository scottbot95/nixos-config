{ config, lib, modulesPath, ...}:
{
  imports = [
     "${modulesPath}/profiles/qemu-guest.nix"
  ];

  nixpkgs.system = "x86_64-linux"; # FIXME shouldn't need this but terranix proxmox module currently requires it
  nixpkgs.hostPlatform = lib.systems.examples.gnu64;

  sops.defaultSopsFile = ../../secrets/homelab.yaml;

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
}