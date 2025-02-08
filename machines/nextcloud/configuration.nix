{ config, pkgs, ...}: {
  imports = [
    ../../modules/profiles/proxmox-guest/v2.nix
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  fileSystems."/data" = {
    device = "/dev/vdb"; # TODO can we give the drive a label through terraform?
    fsType = "ext4";
    autoFormat = true; # TODO can we format the drive through terraform?
  };

  scott.sops.enable = true;
  sops.defaultSopsFile = ./secrets.yaml;

  sops.secrets."nextcloud/adminpass" = {
    mode = "0440";
    owner = config.users.users.nextcloud.name;
    group = config.users.users.nextcloud.group;
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30;
    hostName = config.networking.fqdn;
    home = "/data/nextcloud";
    https = true;
    configureRedis = true;
    # caching.apcu = false;
    config.adminpassFile = "/run/secrets/nextcloud/adminpass";
    settings.trusted_domains = ["nextcloud.faultymuse.com"];
    maxUploadSize = "4g";
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
    extraConfig = ''
      fastcgi_request_buffering off;
      proxy_buffering off;
    '';
  };
 
  # services.vsftpd = {
  #   enable = true;
  #   forceLocalLoginSSL = true;
  #   forceLocalDataSSL = true;
  #   userlistDeny = false;
  #   localUsers = true;
  #   userlist = [ "scott" ];
  #   rsaCertFile = "/var/lib/acme/ftp.faultymuse.com/cert.pem";

  #   anonymousUser = true;
  #   anonymousUserNoPassword = true;
  #   anonymousUserHome = "/ftp/public";

  #   extraConfig = ''
  #     force_anon_data_ssl=true
  #     force_anon_login_ssl=true
  #   '';
  # };

  networking.hostName = "nextcloud";
  networking.domain = "prod.faultymuse.com";

  networking.firewall.allowedTCPPorts = [80 443];
  networking.firewall.allowedUDPPorts = [80 443];

  system.stateVersion = "24.05";
}