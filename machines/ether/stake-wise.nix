{ pkgs,
}:
let
  operatorService = pkgs.stdenv.mkDerivation rec {
    pname = "stakewise-operator-service-v3";
    version = "3.0.3";
    src = pkgs.fetchurl {
      url = "https://github.com/stakewise/v3-operator/releases/download/v${version}/operator-v${version}-linux-amd64.tar.gz";
      hash = "sha256-JJaaXbc9ccmj9vBSq6swkCX5MWR/IDadnSWbaStd83A=";
      # hash = pkgs.lib.fakeHash;
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
    ];

    buildInputs = with pkgs; [
      zlib
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -m755 -D operator-v${version}-linux-amd64/operator $out/bin/operator
      runHook postInstall
    '';
  };
in
{
  inherit operatorService;
}