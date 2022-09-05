{ sops-nix, ...}:
{ config, ... }:
{
    imports = [ sops-nix.nixosModules.sops ];

    options = {};

    config = {
        sops.defaultSopsFile = ../../secrets/homelab.yaml;
        sops.age.keyFile = /home/scott/.config/sops/age/keys.txt;
    };
    
}