{config, pkgs, lib, ... }:
{
    scott.technitium.enable = true;
    scott.proxmoxGuest.enable = false;
    deployment.targetHost = "192.168.4.12";
    nixpkgs.crossSystem = {
        system = "aarch64-linux";
        config = "aarch64-unknown-linux-gnu";
    };

    imports = ["${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/936e4649098d6a5e0762058cb7687be1b2d90550.tar.gz" }/raspberry-pi/4"];

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

    # FIXME Doesn't work cuz cross-compile with nixops :( Probably solvable
    # services.hardware.argonone.enable = true;

    users = {
      mutableUsers = false;
      users.guest = {
        isNormalUser = true;
        password = "guest";
        extraGroups = [ "wheel" ];
      };
    };

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