{ config, pkgs, lib, ... }:
let 
  gpg_pub_key = "A954416D9ADA8144";
in 
{
  imports = [
    # ./wpilib
  ];

  home.packages = with pkgs; [
    anydesk

    jetbrains.idea-ultimate
    git
    guake
    htop
    nixpkgs-fmt
    python3
    wget
    vim

    discord
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git"];
      theme = "robbyrussell";
    };

    shellAliases = {
      nixrt = "doas nixos-rebuild test --flake ~/nixos-config";
      nixrb = "nixos-rebuild build --flake ~/nixos-config";
      nixrs = "doas nixos-rebuild switch --flake ~/nixos-config";
      
      switch-yk = "gpg-connect-agent 'scd serialno' 'learn --force' /bye";
    };
  };

  programs.gpg = {
    enable = true;
    publicKeys = [{
      source = ./gpg-0x${gpg_pub_key}.asc;
      trust = "ultimate";
    }];
    settings = {
      # Use AES256, 192, or 128 as cipher
      personal-cipher-preferences =  "AES256 AES192 AES";
      # Use SHA512, 384, or 256 as digest
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      # Use ZLIB, BZIP2, ZIP, or no compression
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      # Default preferences for new keys
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      # SHA512 as digest to sign keys
      cert-digest-algo = "SHA512";
      # SHA512 as digest for symmetric ops
      s2k-digest-algo = "SHA512";
      # AES256 as cipher for symmetric ops
      s2k-cipher-algo = "AES256";
      # UTF-8 support for compatibility
      charset = "utf-8";
      # Show Unix timestamps
      fixed-list-mode = true;
      # No comments in signature
      no-comments = true;
      # No version in output
      no-emit-version = true;
      # Disable banner
      no-greeting = true;
      # Long hexidecimal key format
      keyid-format = "0xlong";
      # Display UID validity
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      # Display all keys and their fingerprints
      with-fingerprint = true;
      # Display key origins and updates
      with-key-origin = true;
      # Cross-certify subkeys are present and valid
      require-cross-certification = true;
      # Disable caching of passphrase for symmetrical ops
      no-symkey-cache = true;
      # Enable smartcard
      use-agent = true;
      # Disable recipient key ID in messages
      throw-keyids = true;
    };
  };

  programs.git = {
    enable = true;
    userName = "Scott Techau";
    userEmail = "scott.techau@gmail.com";

    signing = {
      key = gpg_pub_key;
      signByDefault = true;
    };

    extraConfig = { github.user = "scottbot95"; };
  };

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
      eamodio.gitlens
#      ms-vscode-remote.remote-ssh
    ];
    userSettings = {
      "editor.tabSize" = 2;
      "editor.fontFamily" = "Fira Code";
      "editor.fontLigatures" = true;
      "nix.enableLanguageServer" = true;
      "files.exclude" = {
        "**/.classpath" = true;
        "**/.project" = true;
        "**/.settings" = true;
        "**/.factorypath" = true;
      };
      "remote.SSH.logLevel" =  "trace";
      "workbench.iconTheme" = "material-icon-theme";
    };
  };

  # programs.wpilib = {
  #   enable = true;
  #   configureVsCode = true;
  # };

  programs.chromium = {
    enable = true;
  };

  systemd.user.services.guake = {
    Unit = {
      Description = "Run guake terminal";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.guake}/bin/guake";
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";
}
