{ config, pkgs, lib, steam-servers, ... }:
let
  
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
    steam-servers.nixosModules.default
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "7-days-to-die-server"
    "steamworks-sdk-redist"
    "palworld-server"
    "steam-run"
    "steam-original"
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  scott.sops.enable = true;
  sops.secrets."palworld/mesa/gamePass" = {};
  sops.secrets."palworld/mesa/adminPass" = {};

  scott.sops.envFiles.palworld-mesa = {
    requiredBy = [ "palworld-mesa.service" ];
    vars = {
      SERVER_PASSWORD.secret = "palworld/mesa/gamePass";
      ADMIN_PASSWORD.secret = "palworld/mesa/adminPass";
    };
  };

  services.steam-servers."7-days-to-die".drazz = {
    enable = false;
    openFirewall = true;

    config = {
      GameWorld = "PREGEN10k";
      GameName = "GoeffPlsNoGrief";
    };
  };

  services.steam-servers.palworld.mesa = {
    enable = true;
    openFirewall = true;

    worldSettings = {
      ServerPassword = "@SERVER_PASSWORD@";
      AdminPassword = "@ADMIN_PASSWORD@";
      PalEggDefaultHatchingTime = 25;
    };
  };

  systemd.services.palworld-mesa = {
    serviceConfig.EnvironmentFile = "/run/secrets/palworld-mesa.env";
  };

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "23.05";
}