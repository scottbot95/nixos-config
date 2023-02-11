{ config, lib, pkgs, ...}: {

  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  networking.hostName = "jenkins";

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