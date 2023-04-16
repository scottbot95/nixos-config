{ pkgs
, system
, self
, ...
}:
let
  machines = pkgs.lib.filterAttrs 
    (_: machine: (machine.pkgs.system == system) && (machine.config.terranix != null)) 
    self.nixosConfigurations;
  linkMachines = pkgs.lib.mapAttrsToList (name: machine: "ln -s ${machine.config.system.build.toplevel} $out/${name}") machines;
in derivation {
  inherit system;
  name = "prebuild";
  PATH = "${pkgs.coreutils}/bin";
  builder = pkgs.writeShellScript "prebuild" ''
    mkdir -p $out
    ln -s ${self.packages.${system}.terraformConfig} $out/config.tf.json
    ${builtins.concatStringsSep "\n" linkMachines}
  '';
}