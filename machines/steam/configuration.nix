{ lib, steam-servers, ... }:
{
  imports = [
    ../../modules/profiles/proxmox-guest/v2.nix
    steam-servers.nixosModules.default
    ./factorio.nix
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "7-days-to-die-server"
    "steamworks-sdk-redist"
    "palworld-server"
    "steam-run"
    "steam-original"
    "factorio-headless"
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  scott.sops.enable = true;

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "24.05";
}