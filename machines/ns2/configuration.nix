{ ... }: 
{
  imports = [ 
    ../../modules/profiles/proxmox-guest
  ];

  terranix = {
    imports = [ ./terraform.nix ];
  };

  scott =  {
    technitium = {
      enable = true;
      domain = "ns2.lan.faultymuse.com";
    };
  };

  networking = {
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "10.0.5.2";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.5.1";
  };

  system.stateVersion = "23.05";
}