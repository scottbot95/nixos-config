{ config, lib, faultybox, ... }:
{
  imports = [
    faultybox.nixosModules.faultybox
    ../../modules/profiles/proxmox-guest
  ];

  services.faultybox.enable = true;
  services.faultybox.openFirewall = true;

  system.stateVersion = "23.05";
}