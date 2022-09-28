{ pkgs, inputs, system }:
with pkgs;
mkShell {
    nativeBuildInputs = [
        inputs.hercules-ci-agent.packages.${system}.hercules-ci-cli
    ];
    buildInputs = [
        sops
        inputs.self.packages.${system}.nixops
        inputs.nixops-proxmox.packages.${system}.default
    ];
}