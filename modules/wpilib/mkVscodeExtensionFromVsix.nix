{ pkgs, ... }:
  { name, vsix, vscodeExtUniqueId }:
    pkgs.stdenv.mkDerivation {
      inherit name;

      dontPatchELF = true;
      dontStrip = true;

      src = vsix;

      nativeBuildInputs = with pkgs; [ unzip ];

      installPrefix = "share/vscode/extensions/${vscodeExtUniqueId}";

      unpackPhase = ''
        runHook preUnpack

        unzip ${vsix}

        runHook postUnpack
      '';
      
      installPhase = ''
        runHook preInstall

        mkdir -p "$out/$installPrefix"
        find ./extension -mindepth 1 -maxdepth 1 | xargs -d'\n' mv -t "$out/$installPrefix/"

        runHook postInstall
      '';
    }  
