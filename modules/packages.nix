{ pkgs, ... }:
{
  nixpkgs = {
    config.allowUnfree = true;
    config.packageOverrides = pkgs: {
      python-validity = pkgs.callPackage ../pkgs/python-validity.nix { };
      open-fprintd = pkgs.callPackage ../pkgs/open-fprintd.nix { };
    };
  };

  environment.systemPackages = with pkgs; [
    firefox
    anydesk
    idea.idea-ultimate

    guake
    htop
    nixpkgs-fmt
    unzip
    usbutils

    git
    git-crypt

    arp-scan

    wget
    vim
  ];
}
