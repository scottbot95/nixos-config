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
  terranixModules = 
    mapAttrs
      (name: _: import ./${name}/terraform.nix)
      (dirsWithFile "terraform.nix");
in {
  inherit nixosConfigurations terranixModules;
}