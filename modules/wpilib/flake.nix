{
  description = "WPILib resources";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    utils.url = "github:numtide/flake-utils";

    wpilib.url = "https://github.com/wpilibsuite/allwpilib/releases/download/v2022.2.1/WPILib_Linux-2022.2.1.tar.gz";
    wpilib.flake = false;
  };

  outputs = { self, nixpkgs, wpilib, utils }: 
    utils.lib.eachDefaultSystem (system: 
      let pkgs = nixpkgs.legacyPackages.${system}; in 
      rec {
        packages.sdk = pkgs.stdenv.mkDerivation rec {
          pname = "wpilib";

          version = "2022.2.1";

          src = wpilib;
          
          dontPatchELF = true;
          dontStrip = true;

          year = builtins.head (builtins.splitVersion version);
          installDir = "$out/${year}";

          installPhase = ''
            mkdir -p ${installDir}
            tar xf ${wpilib}/WPILib_Linux-${version}-artifacts.tar.gz -C ${installDir}
          '';
        };

        defaultPackage = packages.sdk;

        packages.extensions = (import ./vscodeExtensions.nix) {
          inherit pkgs;

          wpilib = packages.sdk;
        };
      }
    );
}
