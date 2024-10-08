{ pkgs, ethereum-nix, ... }:
{
  imports = [
    ../../modules/profiles/proxmox-guest/v2.nix
    # ./holesky.nix
    # ./mainnet.nix
    ./gnosis.nix
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
    (final: prev: {
      lighthouse = prev.lighthouse.overrideAttrs (_: prevAttrs: {
        cargoBuildFeatures = prevAttrs.cargoBuildFeatures ++ [ "gnosis" "jemalloc" ];
      });
      nimbus = prev.nimbus.overrideAttrs (_: prevAttrs: {
        NIMFLAGS = "${prevAttrs.NIMFLAGS} -d:gnosisChainBinary -d:const_preset=gnosis";
      });
    })
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  scott.sops.enable = true;

  environment.systemPackages = [
    pkgs.lighthouse
    # pkgs.reth
    pkgs.nimbus
  ];

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "24.05";
}
