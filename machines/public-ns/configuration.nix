{ config, pkgs, ...}: 
{
  imports = [ 
    ../../modules/profiles/nameserver
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."namesilo/api_key" = {};

  scott.sops.envFiles.acme = {
    requiredBy = ["acme-${config.networking.fqdn}.service" "acme-${config.networking.hostName}.service"];
    vars = {
      PDNS_API_URL.text = "http://127.0.0.1:8081";
      PDNS_API_KEY.secret = "pdns/api_key";
    };
  };

  networking = {
    hostName = "ns1";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "10.0.20.2";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.20.1";
  };

  services.powerdns.extraConfig = ''
    dnsupdate=yes
    gmysql-dnssec=yes
    allow-dnsupdate-from=10.0.5.0/8 192.168.4.0/8
  '';

  security.acme.acceptTerms = true;
  security.acme.defaults = {
    email = "scott.techau+acme@gmail.com";
    dnsProvider = "pdns";
    credentialsFile = "/run/secrets/acme.env";
    dnsPropagationCheck = false;
  };
  security.acme.certs."${config.networking.fqdn}" = {
    group = "nginx";
  };
  # security.acme.certs."${config.networking.hostName}" = {
  #   domain = config.networking.fqdn;
  # };
  
  services.nginx = {
    enable = true;

    # Use recommended settings
    virtualHosts."${config.networking.fqdn}" = {
      onlySSL = true; # only needed so that certificate options are used
      sslCertificate        = "/var/lib/acme/${config.networking.fqdn}/fullchain.pem";
      sslCertificateKey     = "/var/lib/acme/${config.networking.fqdn}/key.pem";
      sslTrustedCertificate = "/var/lib/acme/${config.networking.fqdn}/chain.pem";
      listen = [{
        addr = "0.0.0.0";
        port = 9443;
        ssl = true;
      }];

      locations."/" = {
        proxyPass = "http://127.0.0.1:8081";
      };
    };

    virtualHosts."${config.networking.hostName}" = {
      # enableACME = true;
      useACMEHost = config.networking.fqdn;
      acmeRoot = null;
      forceSSL = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 9443 ];

  networking.nameservers = [ "192.168.4.2" ];
  networking.domain = "prod.faultymuse.com";

  scott.dns-updater = {
    enable = true;
    namesilo.keyFile = config.sops.secrets."namesilo/api_key".path;
    pdns.keyFile = config.sops.secrets."pdns/api_key".path;
  };
}