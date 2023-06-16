{ lib, config, pkgs, self, ... }:
with lib;
let
  cfg = config.services.python-validity;
  flakePkgs = self.packages.${pkgs.system};
  validityPkgs = with flakePkgs; [open-fprintd python-validity];
in {
  options.services.python-validity = {
    enable = mkEnableOption "Python driver for validity fingerprint readers";
  };

  config = mkIf cfg.enable {
    # Still need original fprintd for fprintd-* commands
    environment.systemPackages = with pkgs; [ fprintd ];

    systemd = {
      packages = validityPkgs;
      services.python3-validity.wantedBy = [ "default.target" ];

      # Dirty hack to fix https://github.com/uunicorn/python-validity/issues/106
      services.validity-restart =
        let
          targets = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
        in
        {
          description = "Restart services to fix fingerprint integration";
          wantedBy = targets;
          after = targets;
          serviceConfig = {
            type = "oneshot";
            ExecStart = "systemctl restart open-fprintd.service python3-validity.service";
          };
        };
    };

    services.dbus.packages = validityPkgs;

    security.pam.services = {
      doas.fprintAuth = true;
      login.fprintAuth = true;
      xscreensaver.fprintAuth = true;
    };
  };

}