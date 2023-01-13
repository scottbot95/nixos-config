{ pkgs ? import <nixpkgs> {},
  system ? pkgs.system,
  flake ? null,
}:
let
  safeFlake = 
    if flake != null then 
      flake
    else
      builtins.getFlake (toString ./.);
  system = pkgs.system;
in 
with pkgs;
mkShell {
    nativeBuildInputs = [
        safeFlake.inputs.hercules-ci-agent.packages.${system}.hercules-ci-cli
    ];
    buildInputs = [
        cachix
        sops
        fly
        safeFlake.packages.${system}.nixops
        safeFlake.inputs.nixops-proxmox.packages.${system}.default
    ];
}