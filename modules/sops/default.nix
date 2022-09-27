{ root, config, lib, ... }:
let
  cfg = config.scott.sops;
in with lib; {
    # TODO shoould be able to have import here but nixops doesn't let us add specialArgs
    # imports = [ inputs.sops-nix.nixosModules.sops ];

    options.scott.sops = {
      enable = mkEnableOption "Enable SOPS secrets";
      ageKeyFile = mkOption {
        type = types.path;
        default = "/home/scott/.config/sops/age/keys.txt";
        description = "Path to age key used decrypt secrets file";
      };
    };

    config = mkIf cfg.enable {
        sops.defaultSopsFile = /${root}/secrets/homelab.yaml;
        sops.age.keyFile = cfg.ageKeyFile;
    };
    
}