{ config, pkgs, ... }:
{
  imports = [
    # ./wpilib
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
    userEmail = "scott.techau@gmail.com";

    signing = {
      key = "A954416D9ADA8144";
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
