{ config, lib, pkgs, modulesPath, ... }:
let
  mkSubvolume = mp: name: "btrfs subvolume create ${mp}/${name}";
in {
  imports = [
    ../../../modules/proxmox-guest.nix
  ];

  networking.hostName = "nixops-success";

  deployment.proxmox.disks = [
    ({
      volume = "nvme0";
      size = "20G";
      enableSSDEmulation = true;
      enableDiscard = true;
    })
  ];
  
  deployment.proxmox.memory = 2048;
  deployment.proxmox.cores = 2;
}