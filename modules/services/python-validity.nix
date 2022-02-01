{ lib, config, pkgs, ... }:
let
  cfg = config.services.python-validity;
  open-fprintd = pkgs.callPackage ../../pkgs/open-fprintd.nix { };
  python-validity = pkgs.callPackage ../../pkgs/python-validity.nix { };
in with lib; {
  
  options.services.python-validity = {
    enable = mkEnableOption "python-validity";
  };

  config = mkIf cfg.enable {
    # Still need original fprintd for fprintd-* commands
    environment.systemPackages = with pkgs; [ fprintd ];

    systemd = {
      packages = [ open-fprintd python-validity ];
      services.python3-validity.wantedBy = [ "default.target" ];
    };

    services.dbus.packages = [ open-fprintd python-validity ];

    security.pam.services = {
      doas.fprintAuth = true;
      login.fprintAuth = true;
      xscreensaver.fprintAuth = true;
    };
  };
}