{ config, pkgs, lib, self, ... }:
with lib;
let
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  environment.systemPackages = with pkgs; [
    step-cli
  ];

  services.step-ca = {
    enable = true;
    settings = importJSON ./ca.json;
    port = 443;
    address = "0.0.0.0";
    openFirewall = true;
    intermediatePasswordFile = "/root/.capass";
  };

  system.stateVersion = "23.11";
}
