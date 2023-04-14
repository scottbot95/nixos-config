{ pkgs, lib, modulesPath,...}: {
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
    ../../modules/profiles/well-known-users
  ];

  proxmoxLXC = {
    privileged = true;
  };

  nixpkgs.system = "x86_64-linux"; # FIXME shouldn't need this but terranix proxmox module currently requires it
  nixpkgs.hostPlatform = lib.systems.examples.gnu64;

  fileSystems."/export/data" = {
    device = "/mnt/nfs_datadir_1";
    options = [ "bind" ];
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export       10.0.0.0/16(rw,fsid=0,no_subtree_check,no_root_squash) 192.168.4.0/24(rw,fsid=0,no_subtree_check,no_root_squash)
    /export/data  10.0.0.0/16(rw,nohide,insecure,no_subtree_check,no_root_squash) 192.168.4.0/24(rw,nohide,insecure,no_subtree_check,no_root_squash)
  '';

  services.samba-wsdd.enable = true; # Enable visibility for windows
  services.samba = {
    enable =true;
    extraConfig = ''
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 192.168.4. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      data = {
        path = "/export/data";
        browseable = true;
        "read only" = true;
        "guest ok" = true;
      };
    };
    openFirewall = true;
  };

  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [
    2049 # NFS
    5357 # WSSD
  ];
  networking.firewall.allowedUDPPorts = [
    3702 # WSSD
  ];

  system.stateVersion = "23.05";
}