{ config, pkgs, lib, faulty-trader, ... }:
let
in
{
  imports = [
    faulty-trader.nixosModules.faulty-trader
    ../../modules/profiles/proxmox-guest/v2.nix
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  
  scott.sops.enable = true;

  services.faulty-trader = {
    enable = true;    
  };

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "24.05";
}
