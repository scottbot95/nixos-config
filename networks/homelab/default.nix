{ pkgs, subDirs, lib,  ... }:
let
  machines = builtins.listToAttrs (
    builtins.map 
      (name: {
        inherit name;
        value = import ./${name}/configuration.nix;
      })
      (subDirs ./.)
  );
  nameserver = machineName: (import ./nameserver.nix);
in
machines // {
  network = {
    description = "Scott's Homelab NixOps Networks";
    storage.legacy = {};
    enableRollback = true;
  };

  defaults = {
    scott.proxmoxGuest.enable = lib.mkDefault true;
  };

  ns1 = nameserver "";
  localns = nameserver "";
}