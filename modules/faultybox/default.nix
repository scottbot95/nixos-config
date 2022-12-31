{ config, pkgs, lib, ...}:
let
  cfg = config.scott.faultybox;
  faultybox = (import (pkgs.fetchFromGitHub {
    owner = "scottbot95";
    repo = "faultybox";
    rev = "56caaf874253a27df87a608b3796539162d86a06";
    sha256 = "sha256-FBqBH8Onv0hVRWAD6AMCPTygA7NgBxXt/ezLGXSZI5c=";
  })).default;
in
with lib; {
  options.scott.faultybox = {
    enable = mkEnableOption "FaultyBox Game server";
    package = mkOption {
      type = types.package;
      default = faultybox;
      defaultText = "faultybox@9b6e14";
      description = "Set version of faultybox package to use";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.faultybox = {
      description = "FaultyBox Game server";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      restartIfChanged = true;

      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${cfg.package}/bin/server --addr 0.0.0.0";
        Restart = "always";
      };
    };

    networking.firewall.allowedTCPPorts = [ 8080 ];
    networking.firewall.allowedUDPPorts = [ 8080 ];
  };
}