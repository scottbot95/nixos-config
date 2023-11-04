{ config, pkgs, lib, steam-servers, ... }:
let
  
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
    steam-servers.nixosModules.default
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steamworks-sdk-redist"
  ];

  services.steam-servers."7-days-to-die".drazz = {
    enable = true;
    openFirewall = true;
  };

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "23.05";
}