{ ... }:
let
  subDirs =
    path:
    let
      contents = builtins.readDir path;
    in
    builtins.filter (p: contents.${p} == "directory") (builtins.attrNames contents);
in
{
  # Output all modules in ./modules to flake. Module must be in individual
  # subdirectories and contain a default.nix which contains a standard NixOS module 
  flake.nixosModules =
    let
      validModules = builtins.filter (d: builtins.pathExists ./${d}/default.nix) (subDirs ./.);
    in
    (builtins.listToAttrs (
      builtins.map (m: {
        name = m;
        value = import ./${m};
      }) validModules
    ));
}
