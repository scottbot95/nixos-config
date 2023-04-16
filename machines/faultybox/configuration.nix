{ config, lib, faultybox, ... }:
{
  imports = [
    faultybox.nixosModules.faultybox
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  services.faultybox.enable = true;
  services.faultybox.openFirewall = true;

  system.stateVersion = "23.05";
}