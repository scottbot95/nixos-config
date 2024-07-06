{ config, pkgs, lib, self, ... }:
let
in
{
  imports = [
    ../../modules/profiles/proxmox-guest/v2.nix
    ../../modules/profiles/seedbox
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "unrar"
  ];

  services.transmission.settings = {
    download-dir = "/mnt/downloads";
    incomplete-dir-enabled = true;
  };

  fileSystems."/mnt/downloads" = {
    device = "${self.nixosConfigurations.nas.config.networking.fqdn}:/downloads";
    fsType = "nfs";
  };

  system.stateVersion = "23.05";
}
