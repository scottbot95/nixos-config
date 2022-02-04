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

  # FIXME We shouldn't need this but for some reason gpgconf can't find
  #       the ssh socket on its own so we have to help out
  environment.shellInit = ''
    export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
  '';

  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  home-manager.users.scott = {
    programs.zsh.shellAliases = {
      switch-yk = "gpg-connect-agent 'scd serialno' 'learn --force' /bye";
    };
  };
}