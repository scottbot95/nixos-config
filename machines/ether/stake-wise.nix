{ pkgs,
}:
let
  operatorService = pkgs.stdenv.mkDerivation rec {
    pname = "stakewise-operator-service-v3";
    version = "3.0.1";

    src = pkgs.fetchurl {
      url = "https://github.com/stakewise/v3-operator/releases/download/v${version}/operator-v${version}-linux-amd64.tar.gz";
      hash = "sha256-A2Q90UKLtsbQOzLLYiZ0mR1v1xKEmbSp6xvhvntoihQ=";
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