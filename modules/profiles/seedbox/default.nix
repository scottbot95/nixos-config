# Imported and modified from https://github.com/tadfisher/flake/blob/ac87a52f3813b1196522710e8e5e01c2094dfbb7/nixos/profiles/seedbox.nix

{ config, lib, pkgs, ... }:

with lib;
let
  piaInterface = config.services.pia-vpn.interface;

  processTorrent = pkgs.writeScript "process-torrent" ''
    #!${pkgs.stdenv.shell}
    cd "$TR_TORRENT_DIR"
    if [ -d "$TR_TORRENT_NAME" ]; then
      cd "$TR_TORRENT_NAME"
      for dir in $(find . -name '*.rar' -exec dirname {} \; | sort -u); do
        pushd $dir; ${pkgs.unrar}/bin/unrar x *.rar; popd
      done
    in
  '';

  startTransmission = pkgs.writeScript "start-transmission" ''
    #!${pkgs.stdenv.shell}
    set -e
    IP=$(${pkgs.iproute2}/bin/ip -j addr show dev ${piaInterface} | ${pkgs.jq}/bin/jq -r '.[0].addr_info | map(select(.family == "inet"))[0].local')
    ${pkgs.transmission}/bin/transmission-daemon -f \
      -g "${config.services.transmission.home}/.config/transmission-daemon" \
      --bind-address-ipv4 $IP
  '';

  sopsFile = ./secrets.yaml;
in
{
  sops.secrets."pia/user" = { inherit sopsFile; };
  sops.secrets."pia/pass" = { inherit sopsFile; };
  sops.secrets."transmission/rpc/user" = { inherit sopsFile; };
  sops.secrets."transmission/rpc/pass" = { inherit sopsFile; };

  scott.sops.enable = true;
  scott.sops.envFiles ={
    pia = {
      vars = {
        PIA_USER.secret = "pia/user";
        PIA_PASS.secret = "pia/pass";
      };
      requiredBy = [ "pia-vpn.service" ];
    };
    transmission = {
      vars = {
        rpc-username.secret = "transmission/rpc/user";
        rpc-password.secret = "transmission/rpc/pass";
      };
      requiredBy = [ "transmission.service" ];
      format = "json";
    };
  };

  services = {
    pia-vpn = {
      enable = true;
      portForward = {
        enable = true;
        script = ''
          ${pkgs.transmission}/bin/transmission-remote --port $port || true
        '';
      };
    };

    transmission = {
      enable = true;
      settings = {
        download-queue-enabled = true;
        download-queue-size = 3;
        encryption = 1;
        idle-seeding-limit = 2;
        idle-seeding-limit-enabled = false;
        incomplete-dir-enabled = mkDefault false;
        peer-limit-global = 1033;
        peer-limit-per-torrent = 310;
        peer-port = 61030;
        peer-port-random-high = 65535;
        peer-port-random-low = 16384;
        peer-port-random-on-start = true;
        peer-socket-tos = "lowcost";
        port-forwarding-enabled = false;
        queue-stalled-enabled = true;
        queue-stalled-minutes = 30;
        ratio-limit = 4;
        ratio-limit-enabled = true;
        rename-partial-files = true;
        rpc-bind-address = "0.0.0.0";
        rpc-enabled = true;
        # rpc-password = "";
        rpc-port = 9091;
        rpc-url = "/transmission/";
        # rpc-username = "";
        rpc-host-whitelist = "*";
        rpc-whitelist = "192.168.*.*,127.0.0.1";
        rpc-whitelist-enabled = false;
        scrape-paused-torrents-enabled = true;
        script-torrent-done-enabled = true;
        script-torrent-done-filename = processTorrent;
        seed-queue-enabled = false;
        speed-limit-up = 10240;
        speed-limit-up-enabled = true;
        start-added-torrents = true;
        trash-original-torrent-files = false;
        umask = 2;
        upload-slots-per-torrent = 14;
        utp-enabled = true;
        # defaults to $home/watchdir, but that doesn't exist due to bug in NixOS module...
        watch-dir = "${config.services.transmission.home}/watch-dir";
        watch-dir-enabled = true;
      };
      credentialsFile = config.scott.sops.envFiles.transmission.path;
    };
  };

  systemd.services.transmission = {
    after = [ "pia-vpn.service" ];
    bindsTo = [ "pia-vpn.service" ];
    requires = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = mkForce ''
      ${startTransmission}
    '';
    serviceConfig.RestrictAddressFamilies = [ "AF_NETLINK" ];
  };

  networking.firewall = {    
    allowedTCPPorts = [ config.services.transmission.settings.rpc-port ];
    allowedUDPPorts = [ config.services.transmission.settings.rpc-port ];

    interfaces.${config.services.pia-vpn.interface} = {
      allowedTCPPortRanges = [{ from = 1000; to = 65535; }];
      allowedUDPPortRanges = [{ from = 1000; to = 65535; }];
    };
  };
}