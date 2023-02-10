{ nixpkgs, ... }@inputs:
with builtins;
with nixpkgs.lib;
let
  dirs = filterAttrs (_: type: type == "directory" ) (readDir ./.);
  nixosConfigurations = mapAttrs (name: _: nixosSystem (import ./${name} inputs)) dirs;
  terranixModules = 
    mapAttrs
      (name: _: import ./${name}/terraform.nix)
      (filterAttrs (dir: _: pathExists ./${dir}/terraform.nix) dirs);
in {
  inherit nixosConfigurations terranixModules;
}