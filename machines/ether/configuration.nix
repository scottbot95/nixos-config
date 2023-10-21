{ config, pkgs, lib, ethereum-nix, ... }:
let
  system = pkgs.system;
  unitNames = serviceType: (map 
      (name: "${serviceType}-${name}.service")
      (builtins.attrNames config.services.ethereum.${serviceType}));
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
    ./holesky.nix
    ./mainnet.nix
    ethereum-nix.nixosModules.default
  ];

  nixpkgs.overlays = [
    ethereum-nix.overlays.default
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";

  environment.systemPackages = [
    ethereum-nix.packages.${system}.lighthouse
    ethereum-nix.packages.${system}.erigon
  ];

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "23.05";
}
