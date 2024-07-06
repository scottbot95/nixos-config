{ config, pkgs, lib, nix-minecraft, ... }:
let
  tekxitPi = pkgs.fetchzip {
    url = "https://tekxit.lol/downloads/tekxit3.14/1.0.961TekxitPiServer.zip";
    hash = lib.fakeHash;
  };
  the122Pack = pkgs.fetchzip {
    url = "https://solder.endermedia.com/repository/downloads/the-1122-pack/the-1122-pack_1.5.5.zip";
    hash = "sha256-v9EbAv9w00BbTA4f9JUmcQ0CIQKsJbSAGE3MLbGy57w=";
    stripRoot = false;
  };

  the122PackServer = pkgs.writeShellScriptBin "the122Pack" ''
    echo "serverJar=${the122Pack}/minecraft_server.1.12.2.jar" >> fabric-server-launcher.properties
    cp -R ${the122Pack}/mods .
    chmod 775 mods
    exec ${pkgs.openjdk8}/bin/java $@ -jar ${the122Pack}/forge-1.12.2-14.23.5.2860.jar nogui
  '';
in
{
  imports = [
    ../../modules/profiles/proxmox-guest/v2.nix
    nix-minecraft.nixosModules.minecraft-servers
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  nixpkgs.overlays = [ nix-minecraft.overlay ];

  environment.systemPackages = with pkgs; [
    tmux
    the122PackServer
  ];

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."meinkraft/rcon" = {};

  scott.sops.enable = true;
  scott.sops.ageKeyFile = "/var/keys/age";

  scott.sops.envFiles.meinkraft = {
    vars = {
      RCON_PASS.secret = "meinkraft/rcon";
    };

    owner = config.services.minecraft-servers.user;
    group = config.services.minecraft-servers.group;

    requiredBy = [ "minecraft-server-meinkraft.service" ];
  };

  scott.sops.envFiles.meinkraft-exporter = {
    vars = {
      MC_RCON_PASSWORD.secret = "meinkraft/rcon";
    };

    requiredBy = [ "prometheus-meinkraft-exporter.service" ];
  };

  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;
    environmentFile = config.scott.sops.envFiles.meinkraft.path;
    servers = {
      meinkraft = {
        enable = true;
        package = the122PackServer;
        jvmOpts = "-Xmx20G -Xms2G -Dfml.queryResult=confirm -Djava.awt.headless=true";

        symlinks = { 
          # "mods" = "${the122Pack}/mods";
          "patchouli_book" = "${the122Pack}/patchouli_books";
          "structures" = "${the122Pack}/structures";
          "libraries" = "${the122Pack}/libraries";
          # "config" = "${the122Pack}/config"; 
        };

        serverProperties = {
          max-tick-time = -1;
          "query.port" = 25565;
          force-gamemode = false;
          allow-nether = true;
          gamemode = 0;
          enable-query = true;
          player-idle-timeout = 0;
          difficulty = 2;
          spawn-monsters = true;
          op-permission-level = 4;
          pvp = true;
          snooper-enabled = true;
          level-type = "BIOMESOP";
          hardcore = false;
          enable-command-block = false;
          max-players = 10;
          network-compression-threshold = 256;
          max-world-size = 29999984;
          server-port = 25565;
          server-ip = "0.0.0.0";
          spawn-npcs = true;
          allow-flight = true;
          level-name = "world";
          view-distance = 10;
          spawn-animals = true;
          white-list = false;
          generate-structures = true;
          online-mode = true;
          max-build-height = 256;
          prevent-proxy-connections = false;
          use-native-transport = true;
          motd = "\\u00A7lThe 1.12.2 Pack Server v1.5.5";
          enable-rcon = true;
          "rcon.password" = "@RCON_PASS@";
        };
      };
    };
  };

  services.prometheus.exporters.minecraft = let
      name = "meinkraft";
      serverConfig = config.services.minecraft-servers.servers.${name};
      dataDir = "${config.services.minecraft-servers.dataDir}/${name}";
  in {
    enable = true;
    environmentFile = "-${config.scott.sops.envFiles.meinkraft-exporter.path}";
    worldPath = "${dataDir}/${serverConfig.serverProperties.level-name}";
    modServerStats = "forge";
    openFirewall = true;
  };

  networking.domain = "prod.faultymuse.com";

  system.stateVersion = "23.05";
}
