{ pkgs, inputs, system }:
with pkgs;
mkShell {
    nativeBuildInputs = [
        inputs.hercules-ci.packages.${system}.hercules-ci-cli
    ];
    buildInputs = [
        sops
        nixopsUnstable
        haskellPackages.ghcid
        inputs.nixops-proxmox.packages.${system}.default
    ];
}