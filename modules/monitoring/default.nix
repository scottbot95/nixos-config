{ config, lib, ... }:
let
  cfg = config.scott.monitoring;
in
with lib;
{
  imports = [
    ./promtail.nix
  ];

  options.scott.monitoring = {
  };
}