{ nixpkgs, ... }@inputs:
with builtins;
with nixpkgs.lib;
let
  flakeModules = builtins.attrValues inputs.self.nixosModules;
  dirs = filterAttrs (_: type: type == "directory" ) (readDir ./.);
  dirsWithFile = file: filterAttrs (dir: _: pathExists ./${dir}/${file}) dirs;
  nixosConfigurations = mapAttrs (name: _: nixosSystem {
    modules = flakeModules ++ [ 
      ./${name}/configuration.nix
      {
        networking.hostName = mkDefault name;
      }
    ];
    specialArgs = inputs;
  }) (dirsWithFile "configuration.nix");
  vms = mapAttrs (name: machine: (machine.extendModules {
    modules = if (builtins.pathExists ./${name}/test.nix) then [./${name}/test.nix] else [];
    specialArgs = { test = true; };
  }).config.system.build.vm) nixosConfigurations;
in {
  inherit nixosConfigurations vms;
}