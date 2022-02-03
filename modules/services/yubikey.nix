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

  # Depending on the details of your configuration, this section might be necessary or not;
  # feel free to experiment
  # environment.shellInit = ''
  #   export GPG_TTY="$(tty)"
  #   gpg-connect-agent /bye
  #   export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
  # '';

  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}