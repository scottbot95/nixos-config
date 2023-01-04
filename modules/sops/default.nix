{ root, config, lib, pkgs, ... }:
with lib;
let
  cfg = config.scott.sops;
  envFilesType = types.submodule ({name, config, ...}: {
    options = {
      path = mkOption {
        type = types.str;
        default = "/run/secrets/env/${name}";
        defaultText = mdDoc "`/run/secrets/env/\${name}`";
        description = "Path to store created secrets env file.";
      };
      environment = mkOption {
        type = with types; attrsOf str;
        description = mdDoc ''
          Attribute set of environment variables to include in the generated file.
          Values will be used to lookup the secret path from `config.sops.secrets`
        '';
        example = {
          FOO = "my/secret";
        };
      };
    };
  });
in {
    # TODO shoould be able to have import here but nixops doesn't let us add specialArgs
    # imports = [ inputs.sops-nix.nixosModules.sops ];

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
        default = {};
      };
    };

    config = mkIf cfg.enable {
        sops.defaultSopsFile = /${root}/secrets/homelab.yaml;
        sops.age.keyFile = cfg.ageKeyFile;

        systemd.services = mapAttrs'
          (name: value: 
            nameValuePair "make-env-${name}" {
              description = "Create environment file '${name}'";

              wantedBy = [ "multi-user.target" ];

              restartIfChanged = true;

              serviceConfig = {
                Type = "oneshot";
                ExecStart = pkgs.writeShellScript "make-env-${name}" (
                  concatStringsSep "\n" (
                    mapAttrsToList (varName: secretName: ''
                      ${varName}=$(cat ${config.sops.secrets.${secretName}.path})
                    '') value 
                  )
                );
                DynamicUser = true;
              };
            }
          )
          cfg.envFiles;
    };
    
}