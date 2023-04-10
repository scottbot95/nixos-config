{ stdenv
, lib
, pkgs
, makeWrapper
, ...
}:
let
  buildInputs = with pkgs; [
    bash
    curl
  ];
in
stdenv.mkDerivation {
  pname = "dns-udpater";
  version = "0.1.0";
  src = ./dns-updater.sh;

  inherit buildInputs;
  nativeBuildInputs = [ makeWrapper ];

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/dns-updater
    wrapProgram $out/bin/dns-updater \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}