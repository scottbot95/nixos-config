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
        sdk = pkgs.stdenv.mkDerivation {
          inherit (cfg) version;
          pname = "wpilib-sdk";

          src = pkgs.wpilib.installer;

          dontPatchELF = true;
          dontStrip = true;
          noDumpEnvVars = true; # useful for debugging but uneccessary

          unpackPhase = ''
            tar xf $src/WPILib_Linux-${cfg.version}-artifacts.tar.gz
          '';

          installPhase = ''
            mkdir -p ${installDir}
            mv ./* ${installDir}
          '';
        };
        extensions = (import ./vscodeExtensions.nix) {
          inherit pkgs;

          wpilib = sdk;
        };
      in
      {
        home.file.wpilib.source = sdk;

        programs.vscode = {
          enable = true;
          extensions = extensions;
        };
      }
    );
}
