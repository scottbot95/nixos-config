{ config, pkgs, lib, nixos-hardware, ... }:
{
  scott =  {
    technitium = {
      enable = true;
      domain = "ns1.lan.faultymuse.com";
      dhcp = true;
    };
  };

  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
    ../../modules/profiles/well-known-users
  ];

  users.users.root.openssh.authorizedKeys.keyFiles = [
    ./id_ed25519.pub
  ];

  nixpkgs.system = config.nixpkgs.hostPlatform.system; # FIXME shouldn't need this but terranix proxmox module currently requires it
  nixpkgs.hostPlatform = {
    config = "aarch64-unknown-linux-gnu";
    system = "aarch64-linux";
  };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  # environment.systemPackages = with pkgs; [ vim ];

  services.openssh.enable = true;

  services.hardware.argonone.enable = true;

  # Enable GPU acceleration
  # hardware.raspberry-pi."4".fkms-3d.enable = true;

  # services.xserver = {
  #   enable = true;
  #   displayManager.lightdm.enable = true;
  #   desktopManager.xfce.enable = true;
  # };

  # hardware.pulseaudio.enable = true;

  system.stateVersion = "22.11";
}