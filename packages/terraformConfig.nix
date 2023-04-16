{ pkgs
, self
, inputs
, ...
}:
let
  flakeModules = map
    (machine: machine.config.terranix)
    (builtins.attrValues self.nixosConfigurations);
  terranixConfig = inputs.terranix.lib.terranixConfiguration {
    inherit pkgs;
    modules = flakeModules ++ [ ../terranixModules ];
    extraArgs = inputs;
  };
in
terranixConfig