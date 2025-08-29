{ pkgs, lib, modulesPath,...}: {
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
    ../../modules/profiles/well-known-users
    ../../modules/profiles/ca-certs
    ./minio.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";

  terranix = {
    imports = [ ./terraform.nix ];
  };

  proxmoxLXC = {
    privileged = true;
    manageHostName = true; # true means Nix managed, not proxmox managed
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.system = "x86_64-linux"; # FIXME shouldn't need this but terranix proxmox module currently requires it
  nixpkgs.hostPlatform = lib.systems.examples.gnu64;

  system.activationScripts = {
    createExportDirs.text = ''
      mkdir -p /mnt/nfs_datadir_1/data
      chmod -R a+rwx /mnt/nfs_datadir_1/data

      mkdir -p /mnt/nfs_datadir_1/downloads
      chmod -R a+rwx /mnt/nfs_datadir_1/downloads
    '';
  };

  fileSystems."/export/data" = {
    device = "/mnt/nfs_datadir_1/data";
    options = [ "bind" ];
  };
  fileSystems."/export/downloads" = {
    device = "/mnt/nfs_datadir_1/downloads";
    options = [ "bind" ];
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export             10.0.0.0/16(rw,fsid=0,no_subtree_check,no_root_squash) 192.168.4.0/24(rw,fsid=0,no_subtree_check,no_root_squash)
    /export/data        10.0.0.0/16(rw,nohide,insecure,no_subtree_check,no_root_squash) 192.168.4.0/24(rw,nohide,insecure,no_subtree_check,no_root_squash)
    /export/downloads   10.0.0.0/16(rw,nohide,insecure,no_subtree_check,no_root_squash) 192.168.4.0/24(rw,nohide,insecure,no_subtree_check,no_root_squash)
  '';

  users.users.samba = {
    isSystemUser = true;
    group = "samba";
  };
  users.groups.samba = {};

  # Enable visibility for windows
  services.samba-wsdd = {
    enable = true; 
    openFirewall = true;
  };
  services.samba = {
    enable = true;
    # extraConfig = ''
    #   # note: localhost is the ipv6 localhost ::1
    #   hosts allow = 192.168.4. 127.0.0.1 localhost
    #   hosts deny = 0.0.0.0/0
    #   guest account = nobody
    #   map to guest = bad user
    # '';
    settings = {
      global = {
        "hosts allow" = "192.168.4. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      data = {
        path = "/export/data";
        browseable = true;
        "read only" = false;
        "guest ok" = true;
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "samba";
        "force group" = "samba";
      };
      downloads = {
        path = "/export/downloads";
        browseable = true;
        writeable = true;
        "guest ok" = true;
        "create mask" = 0644;
        "directory mask" = 0755;
      };
    };
    openFirewall = true;
  };

  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [
    80
    443
    2049 # NFS
    5357 # WSSD
  ];
  networking.firewall.allowedUDPPorts = [
    3702 # WSSD
  ];

  security.acme.acceptTerms = true;
  security.acme.defaults = {
    email = "scott.techau+acme@gmail.com";
    server = "https://ca.lan.faultymuse.com/acme/acme/directory";
  };

  networking.hostName = "nas";
  networking.domain = "lan.faultymuse.com";

  system.stateVersion = "23.05";
}