{ config, pkgs, lib, faulty-trader, ... }:
let
in
{
  imports = [
    faulty-trader.nixosModules.default
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

  networking.firewall.allowedTCPPorts = [ 8086 ];

  system.stateVersion = "24.05";
}
