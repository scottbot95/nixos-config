{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = [
    pkgs.poetry2nix.cli
    pkgs.pkg-config
    pkgs.libvirt
    pkgs.python310Packages.poetry
  ];
}