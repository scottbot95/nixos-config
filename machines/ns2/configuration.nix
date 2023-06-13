# FIXME ns2 doesn't work at all. Should probably figure this out at some point...
{config, ...}: 
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

  # sops.defaultSopsFile = ./secrets.yaml;

  # scott.powerdns = {
  #   slave = true;
  #   port = 5300;

  #   recursor = rec {
  #     enable = true;
  #     forwardZones = {
  #       "lan.faultymuse.com" = "127.0.0.1:5300";
  #       "prod.faultymuse.com" = "127.0.0.1:5300";
  #     };
  #     allowNotifyFor = builtins.attrNames forwardZones;
  #   };
  # };

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