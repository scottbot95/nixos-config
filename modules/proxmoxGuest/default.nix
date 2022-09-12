{ root, config, lib, pkgs, modulesPath, ... }@args:
let
  cfg = config.scott.proxmoxGuest;
  proxmoxCfg = (lib.importJSON /${root}/secrets/proxmox.json);
in with lib; {
  imports = [
     "${modulesPath}/profiles/qemu-guest.nix"
  ];

  options.scott.proxmoxGuest = {
    enable = mkEnableOption "Enable Proxmox Guest profile";
  };

  config = 
    if (args.deploymentName or null) == null then
      {}
    else 
      (mkIf cfg.enable {
        deployment.hasFastConnection = true;
        deployment.targetEnv = "proxmox";
        deployment.proxmox = {
          inherit (proxmoxCfg.credentials) username tokenName tokenValue;
          serverUrl = "pve.faultymuse.com:8006";

          uefi = {
            enable = true;
            volume = "nvme0";
          };
          network = mkDefault [
            ({bridge = "vmbr1"; })
          ];
          installISO = "local:iso/nixos-22.05.20220320.9bc841f-x86_64-linux.isonixos.iso";
          usePrivateIPAddress = true;
          partitions = ''
            set -x
            set -e
            wipefs -f /dev/sda

            parted --script /dev/sda -- mklabel gpt
            parted --script /dev/sda -- mkpart primary 512MB -2GiB 
            parted --script /dev/sda -- mkpart primary linux-swap -2GiB 100% 
            parted --script /dev/sda -- mkpart ESP fat32 1MB 512MB
            parted --script /dev/sda -- set 3 esp on

            sleep 0.5

            mkfs.ext4 -L nixroot /dev/sda1
            mkswap -L swap /dev/sda2
            swapon /dev/sda2
            mkfs.fat -F 32 -n NIXBOOT /dev/sda3

            mount /dev/disk/by-label/nixroot /mnt

            mkdir -p /mnt/boot
            mount /dev/disk/by-label/NIXBOOT /mnt/boot
          '';
        };

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

        fileSystems = {
          "/" = {
            device = "/dev/sda1";
            fsType = "ext4";
          };
          "/boot" = {
            device = "/dev/sda3";
            fsType = "vfat";
          };
        };
        swapDevices = [
          { device = "/dev/sda2"; }
        ];

        services.qemuGuest.enable = true;
        services.cloud-init.network.enable = true;

        services.openssh = {
          enable = true;
        };

        # Turn of extra docs
        documentation.nixos.enable = false;
      });
}