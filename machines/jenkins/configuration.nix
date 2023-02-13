{ config, lib, pkgs, ...}: {

  imports = [
    ../../modules/profiles/proxmox-guest
  ];
  
  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";
  
  scott.jenkins = {
    enable = true;
    age_key = "sops_key";
    tf_token = "tf_token";
  };

  virtualisation.docker.enable = true;

  system.stateVersion = "23.05";
}