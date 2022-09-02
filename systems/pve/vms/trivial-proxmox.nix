{ config, lib, pkgs, modulesPath, ... }:
let
  mkSubvolume = mp: name: "btrfs subvolume create ${mp}/${name}";
in {
  imports = [
    ../../../modules/proxmox-guest.nix
  ];

  networking.hostName = "nixops-success";

  deployment.targetEnv = "proxmox";
  deployment.proxmox.disks = [
    ({
      volume = "nvme0";
      size = "20G";
      enableSSDEmulation = true;
      enableDiscard = true;
    })
  ];

  fileSystems = {
    "/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/sda3";
      fsType = "fat32";
    };
  };
  swapDevices = [
    { device = "/dev/sda2"; }
  ];
  deployment.proxmox.partitions = ''
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
  deployment.proxmox.memory = 2048;
  deployment.proxmox.cores = 2;

  users.users.scott = {
    isNormalUser = true;
    initialPassword = "password";
  };
}