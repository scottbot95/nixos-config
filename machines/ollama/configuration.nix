{ config, pkgs, lib, steam-servers, nixpkgs-unstable, ... }:
let
  pkgsUnstable = import nixpkgs-unstable {
    inherit (pkgs) system;
  };
in
{
  imports = [
    ../../modules/profiles/proxmox-guest/v2.nix
    steam-servers.nixosModules.default
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  services.ollama = {
    enable = true;
    package = pkgsUnstable.ollama;
    # package = pkgsUnstable.ollama.overrideAttrs rec {
    #   version = "0.5.11";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "ollama";
    #     repo = "ollama";
    #     tag = "v${version}";
    #     hash = "sha256-Yc/FwIoPvzYSxlrhjkc6xFL5iCunDYmZkG16MiWVZck=";
    #     fetchSubmodules = true;
    #   };
    #   vendorHash = "sha256-wtmtuwuu+rcfXsyte1C4YLQA4pnjqqxFmH1H18Fw75g=";
    #   preBuild = "";
    # };
    acceleration = false; # CPU-only
    loadModels = [
      # "deepseek-r1:7b"
    ];
  };

  services.open-webui = {
    enable = true;
    package = pkgsUnstable.open-webui;
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts.${config.networking.fqdn} = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.open-webui.port}";
      proxyWebsockets = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "24.11";
}