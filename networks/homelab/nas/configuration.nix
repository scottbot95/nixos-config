{ config, lib, ... }:
let
in
{
  scott.proxmoxGuest.partition = ''
    wipefs /dev/sdb

    parted --script /dev/sdb -- mklabel gpt
    parted --script /dev/sdb -- mkpart primary 1MB 100%

    sleep 0.5

    mkfs.ext4 -L NIXSTORE /dev/sdb1

    sleep 0.5

    mkdir -p /mnt/nix
    mount /dev/disk/by-label/NIXSTORE /mnt/nix


    wipefs /dev/sdc

    parted --script /dev/sdc -- mklabel gpt
    parted --script /dev/sdc -- mkpart primary 1MB 100%

    sleep 0.5

    mkfs.ext4 -L vardata /dev/sdc1

    # Doesn't actually need to be mounted for install process
    # mkdir -p /mnt/var/lib/data
    # mount /dev/disk/by-label/vardata /mnt/var/lib/data
  '';

  deployment.proxmox = {
    cores = 4;
    memory = 8192;
    startOnBoot = true;
    disks = [
      { 
        volume = "nvme0";
        label = "root";
        size = "50G";
        enableSSDEmulation = true;
        enableDiscard = true;
      }
      {
        volume = "nvme0";
        label = "nix-store";
        size = "500G";
        enableSSDEmulation = true;
        enableDiscard = true;
      }
      {
        volume = "LTS";
        label = "data";
        size = "2048G"; # Can specify in TB? Doesn't seem to work
      }
    ];
    network = [{
      bridge = "vmbr0";
      tag = 5;
    }];
  };

  fileSystems = {
    "/nix" = {
      device = "/dev/sdb1";
      fsType = "ext4";
    };

    "/export/data" = {
      device = "/dev/sdc1";
      fsType = "ext4";
    };
    "/export/nix/store" = {
      device = "/nix/store"; # Should we have a separate folder for this to keep it isolated?
      options = [ "bind" ];
    };
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export       10.0.0.0/16(rw,fsid=0,no_subtree_check,no_root_squash) 192.168.4.0/24(rw,fsid=0,no_subtree_check,no_root_squash)
    /export/data  10.0.0.0/16(rw,nohide,insecure,no_subtree_check,no_root_squash) 192.168.4.0/24(rw,nohide,insecure,no_subtree_check,no_root_squash)
    /export/nix   10.0.0.0/16(rw,nohide,insecure,no_subtree_check,no_root_squash) 192.168.4.0/24(rw,insecure,no_subtree_check,no_root_squash)
  '';

  networking.firewall.allowedTCPPorts = [ 2049 ];

  system.stateVersion = "22.05";
}