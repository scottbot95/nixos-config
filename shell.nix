{ pkgs, inputs, system }:
with pkgs;
mkShell {
    nativeBuildInputs = [
        inputs.hercules-ci-agent.packages.${system}.hercules-ci-cli
    ];
    buildInputs = [
        sops
        nixopsUnstable
        inputs.nixops-proxmox.packages.${system}.default
    ];
}