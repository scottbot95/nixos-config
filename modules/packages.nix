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
    jetbrains.idea-ultimate
    discord
    # yubikey-manager-qt

    guake
    htop
    nixpkgs-fmt
    unzip
    usbutils
    python3

    git
    git-crypt

    arp-scan

    wget
    vim
  ];
}
