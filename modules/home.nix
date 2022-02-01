{ config, pkgs, ... }:
{
  imports = [
    ./wpilib
  ];

  home.packages = with pkgs; [
    thefuck # needed for zsh plugin
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "thefuck" ];
      theme = "robbyrussell";
    };

    shellAliases = {
      nixrt = "doas nixos-rebuild test --flake ~/nixos-config";
      nixrb = "nixos-rebuild build --flake ~/nixos-config";
      nixrs = "doas nixos-rebuild switch --flake ~/nixos-config";
    };
  };

  programs.git = {
    enable = true;
    userName = "Scott Techau";
    userEmail = "scotttechau@gmail.com";

    extraConfig = { github.user = "scottbot95"; };
  };

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
    ];
  };

  programs.wpilib = {
    enable = true;
    version = "2022.2.1";
  };

  programs.chromium = {
    enable = true;
  };
}
