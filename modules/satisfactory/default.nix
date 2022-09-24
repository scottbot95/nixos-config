{ config, pkgs, lib, ... }: 
let
  cfg = config.scott.games.server.satisfactory;
  installDir = "${cfg.rootDir}/${cfg.installDir}";
  executablePath = "${installDir}/Engine/Binaries/Linux/UE4Server-Linux-Shipping";
  mkPortOption = default: description: lib.mkOption {
    inherit default description;
    type = lib.types.ints.unsigned;
  };
  udpPorts = with cfg; [queryPort beaconPort gamePort];
in
{
  options.scott.games.server.satisfactory = with lib; {
    enable = mkEnableOption "Satisfactory Dedicated Server";

    rootDir = mkOption {
      type = types.str;
      default = "/var/lib/satisfactory";
      description = "Root path to satisfactory data dir";
    };

    installDir = mkOption {
      type = types.str;
      default = "SatisfactoryDedicatedServer";
      description = "Path within /var/lib/satisfactory to install the game";
    };
    branch = mkOption {
      type = types.enum [ "public" "experimental" ];
      default = "public";
      description = "Which release branch to install";
    };

    listenAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Address to bind the server to. Null for all available interfaces";
    };

    queryPort = mkPortOption 15777 "Server management port";
    beaconPort = mkPortOption 15000 "Beacon port";
    gamePort = mkPortOption 7777 "Primary game telemetry port";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (builtins.length (lib.unique udpPorts)) == 3;
        message = "Server ports must all be unique";
      }
    ];

    users.users.satisfactory = {
      home = cfg.rootDir;
      isSystemUser = true;
      group = config.users.groups.satisfactory.name;
    };
    users.groups.satisfactory = {};

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "steamcmd"
      "steam-original"
    ];

    networking.firewall.allowedUDPPorts = udpPorts;

    systemd.services.satisfactory-update = {
      before = [ "satisfactory.service" ];
      wantedBy = [ "satisfactory.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.steamcmd}/bin/steamcmd \
          +force_install_dir ${installDir} \
          +login anonymous \
          +app_update 1690800 -beta ${cfg.branch} validate \
          +quit
        ${pkgs.patchelf}/bin/patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 ${executablePath}
      '';
    };

    systemd.services.satisfactory = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      script =
        let
          serverArgs = 
            [ 
              "-ServerQueryPort=${toString cfg.queryPort}"
              "-BeaconPort=${toString cfg.beaconPort}"
              "-Port=${toString cfg.gamePort}"
            ] ++
            (if cfg.listenAddress != null then [ "-multihome=${cfg.listenAddress}" ] else []);
        in
          "${executablePath} FactoryGame ${builtins.concatStringsSep " " serverArgs}";
      serviceConfig = {
        Nice = "-5";
        Restart = "always";
        User = "satisfactory";
        WorkingDirectory = cfg.rootDir;
      };
      environment = {
        LD_LIBRARY_PATH = builtins.concatStringsSep ":" [
          "${installDir}/linux64"
          "${installDir}/Engine/Binaries/Linux"
          "${installDir}/Engine/Binaries/ThirdParty/PhysX3/Linux/x86_64-unknown-linux-gnu"
        ];
      };
    };
  };
}