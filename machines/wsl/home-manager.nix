{config, pkgs, lib, ...}:
let 
  gpg_pub_key = "A954416D9ADA8144";
in {
  home.packages = with pkgs; [
    git
    htop
    vim

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

    shellAliases = let 
      flakeUrl = "~/workplace/nixos-config#wsl";
    in {
      nixrt = "sudo nixos-rebuild test --flake ${flakeUrl}";
      nixrb = "nixos-rebuild build --flake ${flakeUrl}";
      nixrs = "sudo nixos-rebuild switch --flake ${flakeUrl}";

      # FIXME hack to use Windows native GPG until I can fix Yubikey access with in WSL
      gpg = "gpg.exe";
    };

    initExtra = ''
      export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
      if ! ss -a | grep -q "$SSH_AUTH_SOCK"; then
        rm -f "$SSH_AUTH_SOCK"
        wsl2_ssh_pageant_bin="$HOME/.ssh/wsl2-ssh-pageant.exe"
        if test -x "$wsl2_ssh_pageant_bin"; then
          (setsid nohup socat UNIX-LISTEN:"$SSH_AUTH_SOCK,fork" EXEC:"$wsl2_ssh_pageant_bin" >/dev/null 2>&1 &)
        else
          echo >&2 "WARNING: $wsl2_ssh_pageant_bin is not executable."
        fi
        unset wsl2_ssh_pageant_bin
      fi
    '';
  };

  programs.gpg = {
    # Need to figure out Yubikey in WSL... For now just use gpg.exe instead
    enable = false;
    publicKeys = [{
      source = ../../modules/home/users/scott/gpg-0x${gpg_pub_key}.asc;
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

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";
}