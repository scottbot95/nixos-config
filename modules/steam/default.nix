{ config, pkgs, lib, ...}:
with lib;
let
  cfg = config.scott.steam;
in
{
  options.scott.steam = {
    enable = mkEnableOption "Steam";
  };

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        # Copied from Defualt
        extraLibraries = pkgs: with config.hardware.opengl;
            if pkgs.hostPlatform.is64bit
            then [ package ] ++ extraPackages
            else [ package32 ] ++ extraPackages32;
        
        # Block DBUS access for steam because it's PoS
        # https://github.com/ValveSoftware/steam-for-linux/issues/7856
        extraProfile = "export DBUS_SYSTEM_BUS_ADDRESS=";
      };
    };
  };

}