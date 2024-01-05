{ config, options, lib, modulesPath, ...}:
with lib;
{
  imports = [
     "${modulesPath}/profiles/qemu-guest.nix"
     ../well-known-users
     ../ca-certs
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
      { 
        device = "/var/swapfile";
        size = 2048;
      }
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

    services.qemuGuest.enable = true;

    services.openssh = {
      enable = true;
    };

    networking.domain = lib.mkDefault "lan.faultymuse.com";

    # Disable login of root account
    users.users.root.initialPassword = mkDefault "";

    # Enable sending logs to loki by default
    services.promtail.enable = true;

    # Configure ACME to use local ACME server by default
    security.acme.acceptTerms = true;
    security.acme.defaults = {
      email = "scott.techau+acme@gmail.com";
      server = mkDefault "https://ca.prod.faultymuse.com/acme/acme/directory";
    };

    # Enable monitoring on VMs
    services.telegraf = mkIf (config.networking.hostName != "monitoring") {
      enable = true;
      extraConfig = {
        inputs = {
          system = {};
          systemd_units = {};
        };
        outputs = {
          influxdb = {
            database = "homelab";
            urls = [ "http://monitoring.lan.faultymuse.com:8020" ];
          };
        };
      };
    };

    # Turn of extra docs to reduce image size
    documentation.nixos.enable = false;
  } // (if builtins.hasAttr "sops" options then {
    scott.sops.ageKeyFile = "/var/keys/age";
    sops.defaultSopsFile = mkDefault ../../../secrets/homelab.yaml;
  } else {});
}