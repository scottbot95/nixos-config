{ config, options, lib, pkgs, self, ...}:
with lib;
let
  cfg = config.services.pawnsapp;
  pawns-cli = self.packages.${pkgs.system}.pawns-cli;
in
{
  options.services.pawnsapp = {
    enable = mkEnableOption "Pawns.app internet sharing service";
    deviceName = mkOption {
      type = types.str;
      default = config.networking.hostName;
      defaultText = literalExpression "config.networking.hostName";
      description = "Unique name for this device";
    };
    acceptTOS = mkOption {
      type = types.bool;
      example = true;
      description = "Whether or not you accept the TOS. Must be true for pawns to work";
    };
    environmentFile = mkOption {
      type = types.str;
      example = "/run/secrets/pawns.env";
      description = ''
        Environment file that contains the secrets for Pawns.app.

        Should contain at least `PAWNS_EMAIL` and `PAWNS_PASSWORD`
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.pawnsapp = {
      description = "Run the Pawns.app internet sharing service";
      script = ''
        ${pawns-cli}/bin/pawns-cli \
          -email=$PAWNS_EMAIL \
          -password=$PAWNS_PASSWORD \
          -device-name=${cfg.deviceName} \
          ${if cfg.acceptTOS then "-accept-tos" else ""}
      '';
      serviceConfig.EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
    };
  };
}