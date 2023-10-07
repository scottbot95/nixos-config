{ pkgs
, lib
, buildGoModule
, fetchFromGitHub
, ...
}:
let
  
in buildGoModule rec {
  pname = "minecraft-prometheus-exporter";
  version = "0.19.0";

  src = fetchFromGitHub {
    owner = "dirien";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-GVFKGnjZXjjIuTknOTOEmK9Wzilndindtpn0fnntcwM=";
  };

  vendorHash = "sha256-M2yhS1s9Sdq9vh7VvrfQLGFfL9DaqCsA3UoeiV5s63g=";

  meta = with lib; {
    description = "Minecraft Prometheus exporter";
    homepage = "https://github.com/dirien/minecraft-prometheus-exporter";
    license = licenses.asl20;
  };
}