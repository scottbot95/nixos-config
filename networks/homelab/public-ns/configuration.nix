{config, ...}:
{
  imports = [ ../nameserver.nix ];

  deployment.proxmox.network = [{
    bridge = "vmbr0";
    tag = 20;
  }];

  networking = {
    hostName = "ns1";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "10.0.20.2";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.20.1";
  };
}