{ config,... }:
{
  sops.secrets."minio/rootUser/accessKey" = {
    restartUnits = [ "minio.service" ];
  };
  sops.secrets."minio/rootUser/secretKey" = {
    restartUnits = [ "minio.service" ];
  };
  scott.sops.envFiles.minio = {
    vars = {
      MINIO_ROOT_USER.secret = "minio/rootUser/accessKey";
      MINIO_ROOT_PASSWORD.secret = "minio/rootUser/secretKey";
    };
    requiredBy = [ "minio.service" ];
  };

  services.minio = {
    enable = true;
    listenAddress = "127.0.0.1:9000";
    consoleAddress = "127.0.0.1:9001";
    region = "us-west-1";
    # configDir = "/mnt/nfs_datadir_2/minio/config";
    dataDir = ["/mnt/nfs_datadir_2/minio/data"];
    rootCredentialsFile = "/run/secrets/minio.env";
  };
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."s3.lan.faultymuse.com" = {
      forceSSL = true;
      enableACME = true;
      serverAliases = ["s3.us-west-1.faultymuse.com"];

      locations."/" = {
        proxyPass = "http://127.0.0.1:9000";
        extraConfig = ''
          chunked_transfer_encoding off;
        '';
      };
      extraConfig = ''
        # Allow special characters in headers
        ignore_invalid_headers off;
        # Allow any size file to be uploaded.
        # Set to a value such as 1000m; to restrict file size to a specific value
        client_max_body_size 0;
        # Disable buffering
        proxy_buffering off;
        proxy_request_buffering off;
      '';
    };
    virtualHosts."console.s3.lan.faultymuse.com" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:9001";
        proxyWebsockets = true;
      };

      extraConfig = ''
        # Allow special characters in headers
        ignore_invalid_headers off;
        # Allow any size file to be uploaded.
        # Set to a value such as 1000m; to restrict file size to a specific value
        client_max_body_size 0;
        # Disable buffering
        proxy_buffering off;
        proxy_request_buffering off;
      '';
    };
  };
}