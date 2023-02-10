{ nixpkgs, home-manager, nixos-hardware, ...}:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    home-manager.nixosModules.home-manager
    nixos-hardware.nixosModules.lenovo-thinkpad-t480
    ./configuration.nix
  ];
}