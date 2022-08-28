{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ../../../modules/proxmox-guest.nix
  ];

  networking.hostName = "teslamate";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.utf8";

  users.mutableUsers = true;
  users.users.scott = {
    isNormalUser = true;
    description = "Scott";
    extraGroups = ["networkmanager" "wheel" ];
    initialPassword = "password";
  };

  environment.systemPackages = with pkgs; [
    vim
  ];

  system.stateVersion = "22.05";

  proxmox.qemuConf = {
    cores = 2;
    memory = 4098;
    name = "teslamate";
  };
}