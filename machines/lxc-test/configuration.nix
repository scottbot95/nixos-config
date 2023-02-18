{ pkgs, lib, modulesPath,...}: {
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
  ];

  nixpkgs.system = "x86_64-linux"; # FIXME shouldn't need this but terranix proxmox module currently requires it
  # nixpkgs.hostPlatform = lib.systems.examples.gnu64;

  environment.systemPackages = with pkgs; [
    vim
  ];

  system.stateVersion = "23.05";
}