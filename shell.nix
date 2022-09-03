{ pkgs ? import <nixpkgs> {}, inputs }:
with pkgs;
mkShell {
    buildInputs = [
        nixopsUnstable
        inputs.nixops-proxmox
    ];
}