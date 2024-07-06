{ config, pkgs, ... }: {
  imports = [
    ../../modules/profiles/proxmox-guest/v2.nix
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  scott.sops.enable = true;
  sops.defaultSopsFile = ./secrets.yaml;

  sops.secrets."netbox/secret" = {
    mode = "0440";
    owner = config.users.users.netbox.name;
    group = config.users.users.netbox.group;
  };

  services.netbox = {
    enable = true;
    package = pkgs.netbox_3_6;
    listenAddress = "127.0.0.1";

    secretKeyFile = "/run/secrets/netbox/secret";

    settings = {
      ALLOWED_HOSTS = [ config.networking.fqdn ];
    };
  };

  services.nginx = {
    enable = true;
    user = "netbox";
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    virtualHosts.${config.networking.fqdn} = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.netbox.port}";
      };
      locations."/static/" = {
        alias = "${config.services.netbox.dataDir}/static/";
      };
    };
  };

  networking.hostName = "netbox";
  networking.domain = "lan.faultymuse.com";

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 80 443 ];

  system.stateVersion = "23.05";
}
