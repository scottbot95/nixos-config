{ config, lib, pkgs, ...}: {
  config = lib.mkIf config.scott.sops.enable {
    scott.sops.ageKeyFile = "/run/keys/sops-age-key";

    deployment.keys.sops-age-key.keyCommand = [
      "${pkgs.sops}/bin/sops" 
      "--extract" ''["sops_key"]''
      "-d" "secrets/homelab.yaml"
    ];
  };
}