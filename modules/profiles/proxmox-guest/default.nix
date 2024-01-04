{ config, options, lib, modulesPath, ...}:
with lib;
{
  imports = [
     "${modulesPath}/profiles/qemu-guest.nix"
     ../well-known-users
     ../ca-certs
  ];

  config = {
    # Let ops account import unsigned NARs (eg not from cache.nixos.org)
    # TODO maybe we can start signing NARs and add the key?
    nix.settings.trusted-users = [
      "ops"
    ];

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

    networking = {
      useNetworkd = true;
      dhcpcd.enable = false;
      interfaces.ens18.useDHCP = true;
    };

    systemd.network.enable = true;

    # User for performing deployments
    users.users.ops = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };

    # Enabled passwordless sudo for ops account
    security.sudo.extraRules = [{ 
      users = [ "ops" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];

    # Disable login of root account
    users.users.root.hashedPassword = "!";

    # Enable sending logs to loki by default
    services.promtail.enable = true;

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