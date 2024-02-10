{ config, lib, pkgs, nixos-wsl, home-manager, ... }:
{
  imports = [
    # include NixOS-WSL modules
    nixos-wsl.nixosModules.default
    home-manager.nixosModules.home-manager
  ];

  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
  };

  wsl.enable = true;
  wsl.defaultUser = "scott";

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  users.users.scott = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

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
