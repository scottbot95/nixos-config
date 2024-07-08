{ pkgs, ethereum-nix, ... }:
{
  imports = [
    ../../modules/profiles/proxmox-guest
    ./holesky.nix
    ./mainnet.nix
    ethereum-nix.nixosModules.default
  ];

  fileSystems."/mnt/cold-storage" = {
    device = "/dev/vdb1";
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
