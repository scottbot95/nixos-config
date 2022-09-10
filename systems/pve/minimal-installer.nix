{ config, lib, pkgs, modulesPath, ... }:
{
    imports = [
        (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ];

    services.qemuGuest.enable = true;
    services.cloud-init.enable = true;
    services.cloud-init.network.enable = true;
}