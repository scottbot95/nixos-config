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
    users.git-updater = {
      isSystemUser = true;
      group = "git-updater";
    };
    groups.git-updater = [
      config.users.user.git-updater.name
    ];
  };

  systemd.timers.git-updater = {
    wantedBy = [ "timers.target" ];
    partOf = [ "git-updater.service" ];
    # Wait 60 between runs
    timerConfig.OnUnitInactiveSec = 60;
  };
  systemd.services.git-updater = {
    description = "Pull git config from github and apply it";
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/etc/nixos";
      User = config.users.users.git-updater.name;
      Group = config.users.groups.git-updater.group;
    };
    path = with pkgs; [ git nixos-rebuild ];
    script = ''
      git fetch
      old=$(git rev-parse @)
      new=$(git rev-parse @{u})
      if [ $old != $new ]; then
        git rebase --autostash
        echo "Updated git from $old to $new. Deploying change..."
        nixos-rebuild switch --flake .#${config.networking.hostName}
      fi
    '';
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
