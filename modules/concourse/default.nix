{ config, lib, pkgs, self, ...}:
let
  inherit (lib) mkOption mkEnableOption types mdDoc mkIf mkMerge mapAttrsRecursiveCond collect isString findFirst hasPrefix;
  cfg = config.services.concourse-ci;

  concourse = self.packages.${pkgs.system}.concourse;

  mkArg = {
    path,
    value
  }: if (value != null)
    then "--${builtins.concatStringsSep "-" path} ${toString value}"
    else "";

  mkArgs = args:
    collect (v: (isString v) && v != "") (
      mapAttrsRecursiveCond
      (as: !isString as)
      (path: value: mkArg {inherit path value;})
      args
    );
in
{
  options.services.concourse-ci = {
    web = {
      enable = mkEnableOption "Concourse web node";
      user = mkOption {
        type = types.str;
        default = "concourse";
        description = "The user which which the concours web node will run";
      };
      args = mkOption {
        type = types.submodule {
          freeformType = 
            let 
              inherit (types) attrsOf str oneOf;
              argsType = attrsOf (oneOf [str argsType]);
            in
              argsType;

          options = {
            session.signing-key = mkOption {
              type = types.str;
              example = "/run/secrets/concourse_session";
              description = mdDoc "Path to file containing the session signing key";
            };
            tsa = {
              host-key = mkOption {
                type = types.str;
                example = "/run/secrets/host-key";
                description = mdDoc "Path to file containing the `web` private key";
              };
              authorized-keys = mkOption {
                type = types.str;
                example = "/run/secrets/authorized-keys";
                description = mdDoc "Path to file containing a list of authorized `worker` public keys";
              };
            };
          };
        };
        default = {};
        description = mdDoc ''
          Arguments passed into the concourse `web` node.

          Nested keys will be concated together with `-`.
          Eg `session.signing-key` will be converted into the
          `--session-signing-key` flag.
        '';
      };
    };
    worker = {
      enable = mkEnableOption "Concourse worker node";
      args = mkOption {
        type = types.submodule {
          freeformType = with types; oneOf [str];
          options = {
            runtime = mkOption {
              type = types.str;
              default = "containerd";
              description = mdDoc "Runtime to use with the worker.";
            };

            work-dir = mkOption {
              type = types.str;
              default = "/var/lib/concourse-worker";
              description = mdDoc "Data directory used for builds and and where resources are fetched";
            };

            tsa = {
              host = mkOption {
                type = types.str;
                default = "127.0.0.1:2222";
                description = mdDoc "Address and port of the `web` node.";
              };
              public-key = mkOption {
                type = types.str;
                example = "/run/secrets/public-key";
                description = mdDoc "Path to file containing the `web` node public key";
              };
              worker-private-key = mkOption {
                type = types.str;
                example = "/run/secrets/private-key";
                description = mdDoc "Path to file containing the `worker` private key";
              };
            };
          };
        };
        default = {};
        description = mdDoc ''
          Arguments passed into the concourse `worker` node.

          Nested keys will be concated together with `-`.
          Eg `tsa.public-key` will be converted into the
          `--tsa-public-key` flag.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.web.enable (let
      args = mkArgs cfg.web.args;

      # filter out certain args which need to be treated differently
      specialArgs = [
        "--session-signing-key"
        "--tsa-host-key"
      ];

      isNormalArg = name: (findFirst (arg: hasPrefix arg name) null specialArgs) == null;
      filteredArgs = builtins.filter isNormalArg args;

      scriptArgs = ''
        --session-signing-key %d/session-key \
        --tsa-host-key %d/host-key \
        ${builtins.concatStringsSep " \\\n" filteredArgs}
      '';
    in {
      systemd.services.concourse-web = {
        description = "Concourse web node";
        wantedBy = ["multi-user.target"];
        after = ["network.target" "postgresql.service"];
        requires = ["postgresql.service"];

        serviceConfig = {
          DynamicUser = true;
          User = cfg.web.user;
          ExecStart = "${concourse}/bin/concourse web \\\n${scriptArgs}";
          LoadCredential = [
            "session-key:${cfg.web.args.session.signing-key}"
            "host-key:${cfg.web.args.tsa.host-key}"
          ];
        };
      };
    }))
    (mkIf cfg.worker.enable (let
      args = mkArgs cfg.worker.args;

      # filter out certain args which need to be treated differently
      specialArgs = [
        "--tsa-worker-private-key"
      ];

      isNormalArg = name: (findFirst (arg: hasPrefix arg name) null specialArgs) == null;
      filteredArgs = builtins.filter isNormalArg args;

      scriptArgs = ''
        --tsa-worker-private-key %d/private-key \
        ${builtins.concatStringsSep " \\\n" filteredArgs}
      '';
    in {
      systemd.services.concourse-worker = {
        description = "Concourse worker node";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        path = [
          pkgs.iptables
          # Doesn't strictly need busybox but it needs enough random stuff
          # I didn't want to break out explicitly
          pkgs.busybox
        ];

        serviceConfig = {
          # Uses containerd so it needs to run as root
          User = "root";
          ExecStart = "${concourse}/bin/concourse worker \\\n${scriptArgs}";
          StateDirectory = "concourse-worker";
          LoadCredential = [
            "private-key:${cfg.worker.args.tsa.worker-private-key}"
          ];
        };
      };
    }))
  ];
}