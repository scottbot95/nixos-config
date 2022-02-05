{ pkgs, ... }:
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
    nixpkgs-fmt
    unzip
    usbutils

    git
    git-crypt

    wget
    vim
  ];
}
