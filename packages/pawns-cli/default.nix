{ stdenv
, lib
, pkgs
, makeWrapper
, ...
}:
let
  buildInputs = with pkgs; [ ];
in
stdenv.mkDerivation {
  name = "pawns-cli";
  src = pkgs.fetchurl {
    url = "https://cdn.pawns.app/download/cli/latest/linux_x86_64/pawns-cli";
    hash = "sha256-I08vHtShPqmAdK7F3p52DHeEXoARdG5Rtzl7nqw66Ag=";
  };

  inherit buildInputs;
  nativeBuildInputs = [ makeWrapper ];

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 $src $out/bin/pawns-cli
    wrapProgram $out/bin/pawns-cli \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}