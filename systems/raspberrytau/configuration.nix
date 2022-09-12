{ config, inputs, pkgs, lib, ... }:
{
  scott ={
    technitium = {
      enable = true;
      domain = "ns1.lan.faultymuse.com";
      dhcp = true;
    };
  };

  imports = with inputs; [
    nixos-hardware.nixosModules.raspberry-pi-4
    vscode-server.nixosModule
  ];

  nixpkgs.hostPlatform = {
    config = "aarch64-unknown-linux-gnu";
    system = "aarch64-linux";
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = "raspberrytau";
    wireless = {
      enable = false;
      networks."DefinitelyNotAFBISurveillanceVan".psk = null;
      interfaces = [ "wlan0" ];
    };
    interfaces.eth0 = {
      ipv4.addresses = [{
        address = "192.168.4.2";
        prefixLength = 24;
      }];
    };
    defaultGateway = "192.168.4.1";
  };

  environment.systemPackages = with pkgs; [ vim git ];

  services.vscode-server.enable = true;

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
