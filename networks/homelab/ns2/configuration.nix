{config, ...}: 
{
  imports = [ ../nameserver.nix ];

  scott.powerdns = {
    slave = true;
    port = 5300;

    recursor = rec {
      enable = true;
      forwardZones = {
        "lan.faultymuse.com" = "127.0.0.1:5300";
        "prod.faultymuse.com" = "127.0.0.1:5300";
      };
      allowNotifyFor = builtins.attrNames forwardZones;
    };
  };

  deployment.proxmox.network = [{
    bridge = "vmbr0";
    tag = 5;
  }];

  networking = {
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "10.0.5.2";
        prefixLength = 24;
      }];
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    defaultGateway = "10.0.5.1";

    firewall.allowedTCPPorts = [ 53 80 443 ];
    firewall.allowedUDPPorts = [ 53 ];
  };

  # Why do we need this???
  systemd.oomd.enable = false;
}