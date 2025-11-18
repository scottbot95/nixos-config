{ config, pkgs, lib, ... }:
let
  
in
{
  imports = [
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    # imports = [ ./terraform.nix ];
  };

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."honeygain/email" = {};
  sops.secrets."honeygain/pass" = {};
  sops.secrets."pawns/email" = {};
  sops.secrets."pawns/pass" = {};
  
  scott.sops.enable = true;
  scott.sops.envFiles.pawns = {
    vars = {
      PAWNS_EMAIL.secret = "pawns/email";
      PAWNS_PASSWORD.secret = "pawns/pass";
    };
    requiredBy = [ "pawnsapp.service" ];
  };

  
  # Needed for watchtower
  virtualisation.podman.dockerSocket.enable = true;

  virtualisation.oci-containers.containers = {
    honeygain = {
      # Dirty hack to add un-escaped values to start script
      image = "honeygain/honeygain -email $(cat /run/secrets/honeygain/email) -pass $(cat /run/secrets/honeygain/pass)";
      cmd = [
        "-tou-accept"
        "-device" "server1"
      ];
    };

    psclient = {
      autoStart = true;
      image = "packetstream/psclient";
      environment = {
        CID = "5lon";
      };
    };

    watchtower = {
      autoStart = true;
      image = "containrrr/watchtower";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      cmd = [
        "--cleanup"
        "--include-stopped"
        "--include-restarting"
        "--revive-stopped"
        "--interval" "60" 
        "psclient"
      ];
    };
  };

  services.pawnsapp = {
    enable = true;
    acceptTOS = true;
    environmentFile = "/run/secrets/pawns.env";
  };

  networking.domain = "dmz.faultymuse.com";
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  system.stateVersion = "23.05";
}