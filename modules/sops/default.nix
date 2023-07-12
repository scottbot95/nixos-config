{ config, lib, pkgs, sops-nix, ... }:
with lib;
let
  cfg = config.scott.sops;
  users = config.users.users;
  varOptions = { ... }: {
    options = {
      secret = mkOption {
        type = with types; nullOr str;
        description = ''
          Sops secret name to use for this variable.
          Values will be used to lookup the secret path from `config.sops.secrets`
        '';
        default = null;
      };
      text = mkOption {
        type = with types; nullOr str;
        description = "Text literal to use for environment var";
        default = null;
      };
    };
  };
  envFilesType = types.submodule ({ name, config, ... }: {
    options = {
      path = mkOption {
        type = types.str;
        default = "/run/secrets/${name}.env";
        defaultText = literalExpression "/run/secrets/\${name}.env";
        description = "Path to store created secrets env file.";
      };
      vars = mkOption {
        type = with types; attrsOf (submodule varOptions);
        description = mdDoc ''
          Attribute set of environment variables to include in the generated file.
        '';
        example = {
          FOO = "my/secret";
        };
      };
      mode = mkOption {
        type = types.str;
        default = "0400";
        description = ''
          Permissions mode of the in octal.
        '';
      };
      owner = mkOption {
        type = types.str;
        default = "root";
        description = ''
          User of the file.
        '';
      };
      group = mkOption {
        type = types.str;
        default = users.${config.owner}.group;
        defaultText = literalExpression "config.users.users.\${owner}.group";
        description = ''
          Group of the file.
        '';
      };
      requiredBy = mkOption {
        type = with types; listOf str;
        description = "List of systemd services that depend on this file existing";
        default = [ ];
      };
    };
  });
in
{
  options.scott.sops = {
    enable = mkEnableOption "Enable SOPS secrets";
    ageKeyFile = mkOption {
      type = types.str;
      default = "/home/scott/.config/sops/age/keys.txt";
      description = "Path to age key used decrypt secrets file";
    };

    envFiles = mkOption {
      type = types.attrsOf envFilesType;
      description = "Environment files to create based off secrets";
      default = { };
    };
  };

  imports = [
    sops-nix.nixosModules.sops
  ];

  config = mkIf cfg.enable {
    sops.age.keyFile = cfg.ageKeyFile;

    systemd.services = mapAttrs'
      (name: envFile:
        nameValuePair "make-env-${name}" {
          description = "Create environment file '${name}'";

          wantedBy = [ "multi-user.target" ];
          requiredBy = envFile.requiredBy;
          before = envFile.requiredBy;

          restartIfChanged = true;

          serviceConfig = {
            Type = "oneshot";
            ExecStart =
              let
                varLines = concatStringsSep "\n" (
                  mapAttrsToList
                    (varName: varOpts:
                      let
                        value =
                          if varOpts.secret != null then
                            "$(cat ${config.sops.secrets.${varOpts.secret}.path})"
                          else
                            ''"${varOpts.text}"'';
                      in
                      "${varName}=${value}"
                    )
                    envFile.vars
                );
              in
              pkgs.writeShellScript "make-env-${name}" ''
                echo Creating ${envFile.path}
                cat <<EOT > ${envFile.path}
                ${varLines}
                EOT

                chmod ${envFile.mode} ${envFile.path}
                chown ${envFile.owner}:${envFile.group} ${envFile.path}
                echo Done
              '';
          };
        }
      )
      cfg.envFiles;
  };

}
