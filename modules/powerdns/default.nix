{ config, lib, pkgs, ... }:
let 
  cfg = config.scott.powerdns;
  pdnsSrc = pkgs.fetchFromGitHub {
    owner = "PowerDNS";
    repo = "pdns";
    rev = "rec-4.6.2";
    sha256 = "sha256-V1qj5mP9zZAaTkwyuIX9zW2DE7/IRABIh/rMPoAY/9U=";
  };
  schemaScript = "${pdnsSrc}/modules/gmysqlbackend/schema.mysql.sql";
in 
with lib; {
  options.scott.powerdns = {
    enable = mkEnableOption "Nameserver profile";
    saltFile = mkOption {
      type = types.path;
      description = "Salt file used for serializations";
    };
    secretKeyFile = mkOption {
      type = types.path;
      description = "Secret key used for creating session cookies";
    };
    slave = mkEnableOption "PowerDNS slave mode";
  };

  config = mkIf cfg.enable {
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureDatabases = [ "powerdns" ];
      ensureUsers = [
        { name = "pdns";
          ensurePermissions = { "powerdns.*" = "ALL PRIVILEGES"; };
        }
        { name = "powerdnsadmin";
          ensurePermissions = { "powerdns.*" = "ALL PRIVILEGES"; };
        }
      ];
    };

    systemd.services.pdns-init-db = {
      description = "Install PowerDNS schema into MySQL database";
      wants = ["mysql.service"];
      requiredBy = [ "pdns.service" "powerdns-admin.service" ];

      serviceConfig = {
        Type = "oneshot";
        User = config.users.users.pdns.name;
        Group = config.users.users.pdns.group;
      };
      
      script = ''
        set -x
        sleep 5 # Shouldn't need this
        domains=$(${pkgs.mysql}/bin/mysql powerdns -e "SHOW TABLES LIKE 'domains'" | wc -l)
        if [ "$domains" == "0" ]; then
          ${pkgs.mysql}/bin/mysql powerdns < ${schemaScript}
        fi
      '';
    };


    services.powerdns = {
      enable = true;
      extraConfig = ''
        launch=gmysql
        gmysql-user=pdns
        gmysql-host=localhost
        api=yes
        api-key=FIXME-fake-key
        slave=${if cfg.slave then "yes" else "no"}
      '';
    };

    services.powerdns-admin = {
      enable = true;
      inherit (cfg) saltFile secretKeyFile;
      config = ''
        BIND_ADDRESS = '0.0.0.0';
        PORT = 9191
        HSTS_ENABLED = False
        OFFLINE_MODE = False

        SQLA_DB_USER = 'powerdnsadmin'
        SQLA_DB_HOST = 'localhost'
        # SQLA_DB_SOCKET = '/run/mysqld/mysqld.sock'
        SQLA_DB_NAME = 'powerdns'
        SQLALCHEMY_DATABASE_URI = f'mysql://{SQLA_DB_USER}@/{SQLA_DB_NAME}'
        SQLALCHEMY_TRACK_MODIFICATIONS = True
      '';
    };

    systemd.services.powerdns-admin = {
      after = [ "mysql.service" ];
      serviceConfig.BindPaths = "/run/mysqld";
    };

    services.nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedProxySettings = true;
      virtualHosts."${config.networking.hostName}" = {
        http3 = true;
        listenAddresses = [ "0.0.0.0" ];

        locations."/static/" = {
          alias = "${pkgs.powerdns-admin}/share/powerdnsadmin/static/";
        };

        locations."/" = {
          proxyPass = "http://127.0.0.1:8000";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 53 80 443 ];
    networking.firewall.allowedUDPPorts = [ 53 ];
  };
}