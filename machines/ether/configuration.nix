{ pkgs, ethereum-nix, ... }:
{
  imports = [
    ../../modules/profiles/proxmox-guest/v2.nix
    ./holesky.nix
    ./mainnet.nix
    ethereum-nix.nixosModules.default
  ];

  fileSystems."/mnt/hot-storage" = {
    device = "/dev/disk/by-label/hot-storage";
  };
  fileSystems."/mnt/cold-storage" = {
    device = "/dev/disk/by-label/cold-storage";
  };

  nixpkgs.overlays = [
    ethereum-nix.overlays.default
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  scott.sops.enable = true;

  environment.systemPackages = [
    pkgs.lighthouse
    pkgs.erigon
  ];

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "23.05";
}
