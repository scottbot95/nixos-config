{config, ...}: 
{
  imports = [ ../nameserver.nix ];

  scott.powerdns.slave = true;

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
    defaultGateway = "10.0.5.1";
  };
}