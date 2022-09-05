{ pkgs, subDirs, lib, extraArgs, ... }:
let
  machines = builtins.listToAttrs (
    builtins.map 
      (name: {
        inherit name;
        value = pkgs.callPackage ./${name}/configuration.nix extraArgs;
      })
      (subDirs ./.)
  );
in machines // {
  network = {
    description = "Scott's Homelab NixOps Networks";
    storage.legacy = {};
    enableRollback = true;
  };
}