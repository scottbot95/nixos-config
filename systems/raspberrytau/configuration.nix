{ config, inputs, pkgs, lib, ... }:
{
  scott.technitium.enable = true;

  imports = [
    inputs.nixos-hardware.nixosModules.raspberrypi-4
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    wireless = {
      enable = true;
      networks."DefinitelyNotAFBISurveillanceVan".psk = "twowordsalluppercase";
      interfaces = [ "wlan0" ];
    };
  };

  environment.systemPackages = with pkgs; [ vim ];

  services.openssh.enable = true;

  services.hardware.argonone.enable = true;

  users = {
    mutableUsers = false;
    users.guest = {
      isNormalUser = true;
      password = "guest";
      extraGroups = [ "wheel" ];
    };
  };

  # Enable GPU acceleration
  hardware.raspberry-pi."4".fkms-3d.enable = true;

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };

  hardware.pulseaudio.enable = true;

  system.stateVersion = "22.11";

}