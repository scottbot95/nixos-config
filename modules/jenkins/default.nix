{ config, options, pkgs, lib, ... }:
let
  cfg = config.scott.jenkins;
in
with lib;
{
  options.scott.jenkins = {
    enable = mkEnableOption "Jekins web UI";
    age_key = mkOption {
      type = types.str;
      description = ''
        Sops secret name for an AGE key to use by jenkins for decrypting secrets
      '';
      example = "age_key";
    };
    tf_token = mkOption {
      type = types.str;
      description = ''
        Sops secret name for the token used for terraform cloud
      '';
      example = "tf_token";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.${cfg.age_key} = {};
    sops.secrets.${cfg.tf_token} = {};

    scott.sops.envFiles.jenkins = {
      vars = {
        SOPS_AGE_KEY.secret = cfg.age_key;
        TF_TOKEN_app_terraform_io.secret = cfg.tf_token;
      };
      requiredBy = [ "jenkins.service" ];
    };

    services.jenkins = {
      enable = true;
      packages = options.services.jenkins.packages.default ++ (with pkgs; [
        bash
      ]);
      environment = {
        NIX_CONFIG = ''
          experimental-features = nix-command flakes
        '';
      };
      extraJavaOptions = [
        "-Dorg.jenkinsci.plugins.durabletask.BourneShellScript.LAUNCH_DIAGNOSTICS=true"
      ];
    };

    systemd.services.jenkins = { 
      # Use `-` to make env file optional because systemd has
      # some stupid bug where it only checks the existance of the file at system startup
      # not when it actually tries to start that service
      serviceConfig.EnvironmentFile = "-/run/secrets/jenkins.env";
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts = {
        localhost = {
          default = true;
          locations."/".proxyPass = "http://localhost:8080";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}