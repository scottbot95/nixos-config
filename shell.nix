{ pkgs ? import <nixpkgs> {},
  system ? pkgs.system,
  flake ? builtins.getFlake (toString ./.),
}:
let
  system = pkgs.system;
in 
with pkgs;
mkShell {
    buildInputs = [
        sops
    ];
}