{ pkgs ? import <nixpkgs> {},
  system ? pkgs.system,
  flake ? builtins.getFlake (toString ./.),
}:
let
  flakePkgs = flake.packages.${system};
in 
with pkgs;
mkShell {
    buildInputs = [
      jq
      sops
      opentofu
    ];
}