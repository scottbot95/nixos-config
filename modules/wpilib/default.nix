# TODO convert this to a module
{ pkgs,
  wpilib-installer, # Should we just use fetchTarball for this?
  version }:
let
  year = builtins.head (builtins.splitVersion version);
  installDir = "$out/${year}";
  sdk = pkgs.stdenv.mkDerivation {
    inherit version;
    pname = "wpilib-sdk";

    src = wpilib-installer;
    
    dontPatchELF = true;
    dontStrip = true;
    noDumpEnvVars = true; # useful for debugging but uneccessary

    unpackPhase = ''
      tar xf $src/WPILib_Linux-${version}-artifacts.tar.gz
    '';

    installPhase = ''
      mkdir -p ${installDir}
      mv ./* ${installDir}
    '';
  };
in {
  inherit sdk;

  extensions = (import ./vscodeExtensions.nix) {
    inherit pkgs;

    wpilib = sdk;
  };
}