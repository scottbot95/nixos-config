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
        default = "/run/secrets/${name}.${config.format}";
        defaultText = literalExpression "/run/secrets/\${name}.\${format}";
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
      format = mkOption {
        type = types.enum [ "env" "json" ];
        default = "env";
        description = ''
          What format to use when generating the secrets file.

          env: Standard .env format (eg newline-seperated NAME=VALUE pairs)
          json: JSON object
        '';
      };
    };
  });

  writeEnvFile = envFile: {
    env = ''
      # Iterate through environment variables
      for env_var in "''${!ENVFILE_SECRET_@}"; do
        # Extract the key (remainder after the prefix)
        key="''${env_var#ENVFILE_SECRET_}"

        # Get the file path from the environment variable
        file_path="''${!env_var}"

        # Read the content of the file
        value=$(cat "$file_path")

        # Append line to file
        echo "$key=$value" >> ${envFile.path}
      done

      for env_var in "''${!ENVFILE_TEXT_@}"; do
        # Extract the key (remainder after the prefix)
        key="''${env_var#ENVFILE_TEXT_}"

        # Read the content of the variable and use jq to escape as JSON string
        value=$(jq -R . < <(echo "$key"))

        # Append line to file
        echo "$key=\"$value"\" >> ${envFile.path}
      done
    '';
    json = ''
      json_object="{"

      # Iterate through environment variables
      for env_var in "''${!ENVFILE_SECRET_@}"; do
        # Extract the key (remainder after the prefix)
        key="''${env_var#ENVFILE_SECRET_}"

        # Get the file path from the environment variable
        file_path="''${!env_var}"

        # Read the content of the file and use jq to escape as JSON string
        value=$(jq -R . < "$file_path")

        # Add key-value pair to the JSON object
        json_object+="\"$key\":$value,"
      done

      for env_var in "''${!ENVFILE_TEXT_@}"; do
        # Extract the key (remainder after the prefix)
        key="''${env_var#ENVFILE_TEXT_}"

        # Read the content of the variable and use jq to escape as JSON string
        value=$(jq -R . < <(echo "$key"))

        # Add key-value pair to the JSON object
        json_object+="\"$key\":$value,"
      done

      # Remove the trailing comma and close the JSON object
      json_object="''${json_object%,}"
      json_object+="}"

      # Write the final JSON object
      echo "$json_object" > ${envFile.path}
    '';
  }.${envFile.format};
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

          path = with pkgs; [ jq ];

          environment = mapAttrs' (name: varOpts: if varOpts.secret != null then {
            name = "ENVFILE_SECRET_${name}";
            value = config.sops.secrets.${varOpts.secret}.path;
          } else {
            name = "ENVFILE_TEXT_${name}";
            value = varOpts.text;
          }) envFile.vars;

          script = ''
            set -x
            echo Creating ${envFile.path}

            rm -f ${envFile.path}
            touch ${envFile.path}

            ${writeEnvFile envFile}

            chmod ${envFile.mode} ${envFile.path}
            chown ${envFile.owner}:${envFile.group} ${envFile.path}

            echo Done
          '';

          serviceConfig = {
            Type = "oneshot";
            # ExecStart =
            #   let
            #     varLines = concatStringsSep "\n" (
            #       mapAttrsToList
            #         (varName: varOpts:
            #           let
            #             value =
            #               if varOpts.secret != null then
            #                 "$(cat ${config.sops.secrets.${varOpts.secret}.path})"
            #               else
            #                 ''"${varOpts.text}"'';
            #           in
            #           "${varName}=${value}"
            #         )
            #         envFile.vars
            #     );
            #   in
            #   pkgs.writeShellScript "make-env-${name}" ''
            #     echo Creating ${envFile.path}
            #     cat <<EOT > ${envFile.path}
            #     ${varLines}
            #     EOT

            #     chmod ${envFile.mode} ${envFile.path}
            #     chown ${envFile.owner}:${envFile.group} ${envFile.path}
            #     echo Done
            #   '';
          };
        }
      )
      cfg.envFiles;
  };

}
