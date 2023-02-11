{ pkgs ? import <nixpkgs> {},
  system ? pkgs.system,
  flake ? builtins.getFlake (toString ./.),
}:
let
  flakePkgs = flake.packages.${system};
  terraform = pkgs.writeShellScriptBin "terraform" ''
    export PATH=${pkgs.jq}/bin:$PATH
    if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
    cp ${flakePkgs.terraformConfiguration} config.tf.json
    ${pkgs.terraform}/bin/terraform "$@"
  '';
in 
with pkgs;
mkShell {
    buildInputs = [
      sops
      terraform
    ];
}