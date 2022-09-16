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
in
machines // {
  network = {
    description = "Scott's Homelab NixOps Networks";
    storage.hercules-ci = {
      stateName = "homelab.nixops";
    };
    lock.hercules-ci = {
      stateName = "homelab.nixops";
    };
    enableRollback = true;
  };

  defaults = {
    scott.proxmoxGuest.enable = lib.mkDefault true;
  };
}