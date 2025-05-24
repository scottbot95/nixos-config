{ config, lib, pkgs, ... }:
let
  # mods = import ./mods.nix { inherit pkgs lib; };
  mkService = {
    enable ? true,
    saveName,
    stateDirName ? "factorio-${saveName}",
    game-name,
    description ? "",
    port,
    package ? pkgs.factorio-headless,
    extraSettings ? {},
    mods ? [],
    mods-dat ? null,
    secret ? null,
    loadLatestSave ? false,
    admins ? ["FaultyMuse"],
    allowedPlayers ? [],
    extraCliArgs ? "",
    envFile ? null,
  }: 
    let
      stateDir = "/var/lib/${stateDirName}";
      savePath = "${stateDir}/saves/${saveName}.zip";
      configFile = pkgs.writeText "factorio.conf" ''
        use-system-read-write-data-directories=true
        [path]
        read-data=${package}/share/factorio/data
        write-data=${stateDir}
      '';
      serverSettings = {
        name = game-name;
        inherit description;
        max_upload_in_kilobytes_per_second = 0;
        minimum_latency_in_ticks = 0;
        ignore_player_limit_for_returning_players = false;
        allow_commands = "admins-only";
        autosave_interval = "10"; # minutes
        autosave_slots = 15;
        afk_autokick_interval = 0;
        auto_pause = true;
        only_admins_can_pause_the_game = true;
        autosave_only_on_server = true;
        non_blocking_saving = true;
        require_user_verification = true;
        visibility = {
          public = false;
          lan = false;
        };
      } // extraSettings;
      serverSettingsString = builtins.toJSON (lib.filterAttrsRecursive (n: v: v != null) serverSettings);
      serverSettingsFile = pkgs.writeText "server-settings.json" serverSettingsString;
      playerListOption = name: list:
        lib.optionalString ((builtins.isList list) && (list != []))
          "--${name}=${pkgs.writeText "${name}.json" (builtins.toJSON list)}";
      modDir = pkgs.factorio-utils.mkModDirDrv mods mods-dat;
    in lib.mkIf enable {
      description   = "Factorio headless server - ${saveName}";
      wantedBy      = [ "multi-user.target" ];
      after         = [ "network.target" ];

      preStart =
        (toString [
          "test -e ${stateDir}/saves/${saveName}.zip"
          "||"
          "${package}/bin/factorio"
          "--config=${configFile}"
          "--create=${savePath}"
          (lib.optionalString (mods != []) "--mod-directory=${modDir}")
        ])
        + (lib.optionalString (secret != null) ("\necho ${lib.strings.escapeShellArg serverSettingsString}"
          + " \"$(cat $CREDENTIALS_DIRECTORY/server-settings.json)\" | ${lib.getExe pkgs.jq} -s add"
          + " > ${stateDir}/server-settings.json"));

      serviceConfig = {
        Restart = "always";
        KillSignal = "SIGINT";
        DynamicUser = true;
        StateDirectory = stateDirName;
        UMask = "0007";
        ExecStart = toString [
          "${package}/bin/factorio"
          "--config=${configFile}"
          "--port=${toString port}"
          "--bind=0.0.0.0"
          (lib.optionalString (!loadLatestSave) "--start-server=${savePath}")
          "--server-settings=${
            if (secret != null)
            then "${stateDir}/server-settings.json"
            else serverSettingsFile
          }"
          (lib.optionalString loadLatestSave "--start-server-load-latest")
          (lib.optionalString (mods != []) "--mod-directory=${modDir}")
          (playerListOption "server-adminlist" admins)
          (playerListOption "server-whitelist" allowedPlayers)
          (lib.optionalString (allowedPlayers != []) "--use-server-whitelist")
          extraCliArgs
        ];

        # Secrets
        LoadCredential = lib.mkIf (secret != null) [
          "server-settings.json:${config.sops.secrets."${secret}".path}"
        ];
        EnvironmentFile = lib.mkIf (envFile != null) envFile;

        # Sandboxing
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
        RestrictRealtime = true;
        RestrictNamespaces = true;
        MemoryDenyWriteExecute = true;
      };
    };
in
{
  sops.secrets."factorio/spaceAge/server-settings" = {
    restartUnits = ["factorio.service"];
  };
  sops.secrets."factorio/spaceAge/rconPass" = {
    restartUnits = ["factorio.service"];
  };

  scott.sops.envFiles.factorioSpaceAge = {
    vars = {
      RCON_PASS.secret = "factorio/spaceAge/rconPass";
    };
    requiredBy = [ "factorio.service" ];
  };

  sops.secrets."factorio/aa/server-settings" = {
    restartUnits = ["factorio-aa.service"];
  };
  sops.secrets."factorio/aa/rconPass" = {
    restartUnits = ["factorio-aa.service"];
  };

  scott.sops.envFiles.factorioAA = {
    vars = {
      RCON_PASS.secret = "factorio/aa/rconPass";
    };
    requiredBy = [ "factorio-aa.service" ];
  };

  systemd.services.factorio = mkService {
    enable = true;
    stateDirName = "factorio";
    package = pkgs.factorio-headless.overrideAttrs (_: _: rec {
      version = "2.0.49";
      src = pkgs.fetchurl {
        name = "factorio_headless_x64-${version}.tar.xz";
        url = "https://factorio.com/get-download/${version}/headless/linux64";
        sha256= "ef0648ca1ba44c145a3a3e4c174ccd276eb4a335155a20df1ae0e47156fa34ff";
      };
    });

    saveName = "space-age";
    game-name = "Space Age!";
    port = 34197;
    secret = "factorio/spaceAge/server-settings";
    extraCliArgs = "--rcon-port 27015 --rcon-password $RCON_PASS";
    envFile = "/run/secrets/factorioSpaceAge.env";
  };

  systemd.services.factorio-aa = mkService {
    enable = true;
    package = pkgs.factorio-headless.overrideAttrs (_: _: rec {
      version = "2.0.49";
      src = pkgs.fetchurl {
        name = "factorio_headless_x64-${version}.tar.xz";
        url = "https://factorio.com/get-download/${version}/headless/linux64";
        sha256= "ef0648ca1ba44c145a3a3e4c174ccd276eb4a335155a20df1ae0e47156fa34ff";
      };
    });

    saveName = "aa";
    game-name = "Automators Anonymous";

    port = 34297;
    secret = "factorio/aa/server-settings";
    extraCliArgs = "--rcon-port 28015 --rcon-password $RCON_PASS";
    envFile = "/run/secrets/factorioAA.env";

    admins = [
      "FaultyMuse"
      "mkorolko"
      "Gammaraj"
    ];

    # mods = with mods; [
    #   AutoDeconstruct
    #   DiscoScience
    #   Honk
    #   RateCalculator
    #   Todo-List
    #   visible-planets
    #   BottleneckLite
    #   helmod
    #   mining-patch-planner
    #   squeak-through-2
    #   UltimateResearchQueue2
    # ];
  };

  # systemd.services.factorio-backup = {
  #   script = 
  #   let
  #     saveName = config.services.factorio.saveName; 
  #   in ''
  #     printf -v timestamp
  #     cp -p /var/lib/factorio/saves/${saveName}.zip /var/lib/factorio/saves/${saveName}_
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  # };

  networking.firewall.allowedTCPPorts = [ 27015 28015 ];
  networking.firewall.allowedUDPPorts = [ 34197 34297 ];
}