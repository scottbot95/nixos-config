{ pkgs ? import <nixpkgs> {}, inputs }:
with pkgs;
mkShell {
    buildInputs = [
        sops
        nixopsUnstable
        inputs.nixops-proxmox
    ];
}