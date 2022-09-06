{ inputs, ...}:
{ root, config, ... }:
{
    imports = [ inputs.sops-nix.nixosModules.sops ];

    options = {};

    config = {
        sops.defaultSopsFile = /${root}secrets/homelab.yaml;
        sops.age.keyFile = /home/scott/.config/sops/age/keys.txt;
    };
    
}