{ config, pkgs, ... }:
{
  nixpkgs = {
    config.allowUnfree = true;
    config.packageOverrides = pkgs: {
      # override packages here, or add new
    };
  };

  environment.systemPackages = with pkgs; [
    firefox

    guake
    htop
    unzip
    usbutils

    git
    git-crypt
    gnupg

    wget
    vim
  ];
}