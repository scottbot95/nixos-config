{ config, pkgs, lib, ... }:
{
  deployment.targetHost = "192.168.4.2";
  deployment.hasFastConnection = true;
  documentation.nixos.enable = false;

  scott ={
    proxmoxGuest.enable = false;
    technitium = {
      enable = true;
      domain = "ns1.lan.faultymuse.com";
      dhcp = true;
    };
    hercules-ci.agent = {
      enable = true;
      concurrentTasks = 4;
    };
  };

  imports = [
    # TODO can we use the flake inputs here somehow? Or at least be more pure
    "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/raspberry-pi/4"
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF52J7UurrJejQxIU1ag7KvScya9GfQTa08e3a1gnqRd scott.techau@gmail.com"
  ];

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

  environment.systemPackages = with pkgs; [ vim ];

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