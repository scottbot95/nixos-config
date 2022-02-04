{ pkgs, ... }:
{
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Maybe we should consolidate this into packages.nix
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-curses
    pinentry-qt
  ];

  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}