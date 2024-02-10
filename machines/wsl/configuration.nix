{ config
, lib
, pkgs
, nixos-wsl
, home-manager
, vscode-server
, nil
, ... }:
let 
  system = "x86_64-linux";
in
{
  imports = [
    # include NixOS-WSL modules
    nixos-wsl.nixosModules.default
    home-manager.nixosModules.home-manager
    vscode-server.nixosModules.default
  ];

  nixpkgs.hostPlatform = {
    inherit system;
  };

  wsl.enable = true;
  wsl.defaultUser = "scott";
  wsl.extraBin = with pkgs; [
    # Needed for vscode server
    { src = "${coreutils}/bin/uname"; }
    { src = "${coreutils}/bin/dirname"; }
    { src = "${coreutils}/bin/readlink"; }
  ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Setup VSCode server
  programs.nix-ld.enable = true;
  services.vscode-server.enable = true;
  environment.systemPackages = with pkgs;[
    wget
    nil.packages.${system}.nil
  ];

  users.users.scott = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # scott.yubikey.enable = true;
  scott.home.enable = true;

  home-manager.users.scott = import ./home-manager.nix;

  networking.hostName = "nixos";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
