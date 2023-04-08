{config, ...}: 
{
  imports = [ 
    ../../modules/profiles/nameserver
    ../../modules/profiles/proxmox-guest
  ];

  networking = {
    hostName = "ns1";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "10.0.20.3";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.20.1";
  };
}