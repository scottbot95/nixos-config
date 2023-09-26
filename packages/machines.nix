{ pkgs
, system
, self
, ...
}:
let
  machines = pkgs.lib.filterAttrs 
    (_: machine: (machine.pkgs.system == system) && (machine.config.terranix != null)) 
    self.nixosConfigurations;
  toplevels = builtins.mapAttrs 
    (name: machine: machine.config.system.build.toplevel) 
    machines;
  linkMachines = pkgs.lib.mapAttrsToList (name: toplevel: "ln -s ${toplevel} $out/${name}") toplevels;
  buildAll = derivation {
    inherit system;
    name = "machines";
    PATH = "${pkgs.coreutils}/bin";
    builder = pkgs.writeShellScript "machines" ''
      mkdir -p $out
      ln -s ${self.packages.${system}.terraformConfig} $out/config.tf.json
      ${builtins.concatStringsSep "\n" linkMachines}
    '';
  };
in {
  all = buildAll;
} // toplevels