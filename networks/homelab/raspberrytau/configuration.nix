{ config, ...}:
{
  imports = [
    ../../../systems/raspberrytau/configuration.nix
  ];

  deployment.targetHost = "192.168.4.2";

  documentation.enable = false;
}