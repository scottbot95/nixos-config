{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.programs.wpilib;
in
{
  options.programs.wpilib = {
    enable = mkEnableOption "wpilib";

    # FIXME derive this from the package somehow
    version = mkOption {
      type = types.str;
      description = "Version of WPILib provided in pkgs";
    };
  };

  config = mkIf cfg.enable
    (
      let
        year = builtins.head (builtins.splitVersion cfg.version);
        installDir = "$out/${year}";
        sdk = pkgs.wpilib.sdk;
        extensions = pkgs.callPackage ./vscodeExtensions.nix {
          inherit (cfg) version;

          wpilib = sdk;
        };
      in
      {
        home.file.wpilib.source = sdk;

        # TODO make this it's own clean install of VSCode
        programs.vscode = {
          enable = true;
          extensions = extensions;
        };
      }
    );
}
