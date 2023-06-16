{ config, pkgs, lib, home-manager, ...}:
with lib;
let
  cfg = config.scott.home;
  userOptions = {name,...}:{
    options = {
      enable = mkEnableOption "Home manager for user ${name}";
    };
  };
  userModules = mapAttrs' 
    (file: _: {name=removeSuffix ".nix" file; value=import ./users/${file};})
    (filterAttrs
      (name: type: type == "directory" || (hasSuffix ".nix" name))
      (builtins.readDir ./users)
    );
in
{
  imports = [
    home-manager.nixosModules.home-manager
  ];

  options.scott.home = {
    enable = mkEnableOption "Scott's home-manager setup";
    users = mapAttrs (user: _: 
       mkOption {
        type = types.submodule userOptions;
        description = "Home manager settings for user `${user}`";
        default = {};
      })
      userModules;
  };

  config = mkIf cfg.enable {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users = mapAttrs 
      (user: module:
        mkIf cfg.users.${user}.enable module)
      userModules;
  };
}