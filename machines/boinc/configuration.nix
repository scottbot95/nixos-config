{ config, pkgs, lib, ... }:
let
  
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  services.boinc = {
    enable = true;
    extraEnvPackages = with pkgs; [ virtualbox ];
    allowRemoteGuiRpc = true;
  };

  systemd.services.boinc = {
    startLimitBurst = 5;
    startLimitIntervalSec = 120;
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  networking.domain = "prod.faultymuse.com";

  networking.firewall.allowedTCPPorts = [ 31416 ];

  system.stateVersion = "23.05";
}