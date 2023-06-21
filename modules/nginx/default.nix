{ config, lib, pkgs, ... }:
with lib;
let
  certsDir = "/run/certs";
  vhOptions = { name, config, ... }: {
    options.selfSigned = mkEnableOption "creating and using a self-signed cert for this virtual host";

    config = mkIf config.selfSigned {
      sslCertificate = "${certsDir}/${name}.crt";
      sslCertificateKey = "${certsDir}/${name}.key";
    };
  };
  cfg = config.services.nginx.virtualHosts;
in
{
  options.services.nginx.virtualHosts = mkOption {
    type = with types; attrsOf (submodule vhOptions);
  };

  config.systemd.services = mapAttrs'
    (domain: vhCfg: {
      name = "${domain}-create-certificate";
      value = mkIf vhCfg.selfSigned {
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "nginx.service" ];
        before = [ "nginx.service" ];

        script = ''
          mkdir -p ${certsDir}
          ${pkgs.openssl}/bin/openssl req \
            -x509 \
            -noenc \
            -days 365 \
            -newkey rsa:4096 \
            -subj "/O=FaultyMuse/OU=homelab/CN=${domain}" \
            -keyout ${certsDir}/${domain}.key \
            -out ${certsDir}/${domain}.crt

          chown ${config.services.nginx.user}:nginx ${certsDir}/${domain}.{crt,key}
        '';
      };
    })
    cfg;
}
