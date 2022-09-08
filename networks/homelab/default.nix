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
  nameserver = machineName: (pkgs.callPackage ./nameserver.nix extraArgs);
in
machines // {
  network = {
    description = "Scott's Homelab NixOps Networks";
    storage.legacy = {};
    enableRollback = true;
  };

  defaults = {
    scott.proxmoxGuest.enable = true;
  };

  ns1 = nameserver "ns1";
  localns = nameserver "localns";
}