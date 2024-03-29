{ config, lib, pkgs, nodes, name, ...}:
let
  otherNodes = builtins.removeAttrs nodes [ name ];
  mkProxy = ({ 
    name,
    url ? "https://${name}.prod.faultymuse.com",
    proxyWebsockets ? true
  }: {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      inherit proxyWebsockets;
      proxyPass = url;
    };
    
  });
  mkProxies = (proxies: 
    with lib; mapAttrs' 
      (name: args: {
        name = "${name}.faultymuse.com";
        value = mkProxy (args // { inherit name; });
      })
      proxies
    );
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  scott.sops.enable = true;
  sops.defaultSopsFile = ./secrets.yaml;

  # sops.secrets."teslamate/auth_file" = {
  #   mode = "0440";
  #   owner = config.users.users.nginx.name;
  #   group = config.users.users.nginx.group;
  # };

  # Override default from proxmox-guest to use Let's Encrypt for ACME
  security.acme.defaults.server = null;

  networking = {
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "10.0.20.5";
        prefixLength = 24;
      }];
    };
    defaultGateway = {
      address = "10.0.20.1";
      interface = "ens18";
    };
    nameservers = [ "192.168.4.2" "10.0.5.2" ];
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "scott.techau+acme@gmail.com";

  services.nginx = {
    enable = true;
    package = pkgs.nginxQuic;
    statusPage = true;
    
    resolver.addresses = [ "192.168.4.2" "10.0.5.2" ];
    proxyResolveWhileRunning = true;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    commonHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;

      # Enable CSP for your services.
      #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Disable embedding as a frame
      add_header X-Frame-Options DENY;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # Enable XSS protection of the browser.
      # May be unnecessary when CSP is configured properly (see above)
      add_header X-XSS-Protection "1; mode=block";

      # This might create errors
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';

    virtualHosts = lib.mkMerge [
      (mkProxies {
        games = {
          url = "https://faultybox.prod.faultymuse.com";
        };
        # nextcloud = {};
        vault = {};
      })
      {
        "_" = {
          default = true;
          extraConfig = "return 444;";
        };
        # "teslamate.faultymuse.com" = {
        #   locations."/" = {
        #     basicAuthFile = "/run/secrets/teslamate/auth_file";
        #   };
        #   locations."/grafana" = {
        #     # Disable basic auth since grafana has its own
        #   };
        # };
      }
    ];   
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 80 443 ];

  system.stateVersion = "23.05";
}