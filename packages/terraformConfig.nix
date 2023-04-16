{ pkgs
, self
, inputs
, ...
}:
let
  filterNotNull = list: builtins.filter (v: v != null) list;
  flakeModules = filterNotNull (map
    (machine: machine.config.terranix)
    (builtins.attrValues self.nixosConfigurations));
  terranixConfig = inputs.terranix.lib.terranixConfiguration {
    inherit pkgs;
    modules = flakeModules ++ [ ../terranixModules ];
    extraArgs = inputs;
  };
in
terranixConfig