{ config, pkgs, home-manager, nixos-hardware, ... }:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    home-manager.nixosModules.home-manager
    nixos-hardware.nixosModules.lenovo-thinkpad-t480
  ] ++ import ../../modules/module-list.nix;

  nixpkgs.system = "x86_64-linux";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true; # make grub detect other OS's
  boot.loader.systemd-boot.memtest86.enable = true;

  networking.hostName = "marvin"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp3s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  fonts.fonts = with pkgs; [
    fira-code 
    fira-code-symbols
  ];

  # Enable the GNOME 3 Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = false;
  services.xserver.desktopManager.gnome.enable = true;


  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.scott = {
    isNormalUser = true;
    group = "scott";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };
  users.groups.scott = { };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  programs.zsh = {
    enable = true;
    ohMyZsh.enable = true;
  };

  programs.java = { enable = true; package = pkgs.openjdk11; };

  nixpkgs.config = {
    allowUnfree = true;
  };

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.scott = import ../../modules/home.nix;

  # Virutal box setup
  # virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;
  # users.extraGroups.vboxusers.members = [ "scott" ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # List services that you want to enable:

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  # (Experimental) Switch to doas instead of sudo
  security.sudo.enable = false;
  security.doas = {
    enable = true;
    wheelNeedsPassword = true;
    extraRules = [{
      groups = [ "wheel" ];
      noPass = false;
      persist = true;
      keepEnv = true;
    }];
  };

  # services.python-validity.enable = true;
  security.pam.services = {
    doas.fprintAuth = true;
    login.fprintAuth = true;
    xscreensaver.fprintAuth = true;
  };
  
  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  hardware.opengl.enable = true;

  # Hack pls remove :)
  # networking.firewall.allowedTCPPorts = [ 
  #   1250
  #   1735
  #   1740
  # ];
}

