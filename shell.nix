{ pkgs ? import <nixpkgs> {},
  system ? pkgs.system,
  flake ? builtins.getFlake (toString ./.),
}:
let
  system = pkgs.system;
in 
with pkgs;
mkShell {
    nativeBuildInputs = [
        flake.inputs.hercules-ci-agent.packages.${system}.hercules-ci-cli
    ];
    buildInputs = [
        cachix
        sops
        fly
        flake.packages.${system}.nixops
        flake.inputs.nixops-proxmox.packages.${system}.default
    ];
}