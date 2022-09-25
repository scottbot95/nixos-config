{ self, inputs, pkgs, lib, ...}:
with lib;
let
  packagesToImport = 
    filterAttrs
      (path: type: 
        ((type == "regular") && path != "default.nix") ||
        ((type == "directory") && (pathExists "./${path}/default.nix")))
      (builtins.readDir ./.);
  importedPackages = 
    mapAttrs
      (path: _: pkgs.callPackage (import ./${path}) { inherit self inputs; })
      packagesToImport;
  platformPackages = filterAttrs (_: p: elem pkgs.system p.meta.platforms) importedPackages;
in
mapAttrs'
  (path: p: nameValuePair (elemAt (builtins.split ".nix" path) 0) p)
  platformPackages