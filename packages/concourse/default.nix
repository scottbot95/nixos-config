# TODO build from source. 
# Need to figure out how to bundle all the extra things though.
{ lib, stdenv, fetchurl, ... }:
stdenv.mkDerivation rec {
  pname = "concourse";
  version = "7.11.2";
  src = fetchurl {
    url = "https://github.com/concourse/${pname}/releases/download/v${version}/${pname}-${version}-linux-amd64.tgz";
    hash = "sha256-nejPF3Ny5q+pB3AMKuX5Q8nnrCWK6mr7xrD+Psco2YU=";
  };

  installPhase = ''
    mkdir -p $out
    mv ./* $out
  '';

  meta = with lib; {
    description = "Concourse continuous thing-doer";
    mainProgram = "concourse";
    homepage = "https://concourse-ci.org";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}