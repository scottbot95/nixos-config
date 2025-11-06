{ config
, lib
, pkgs
, nixos-wsl
, home-manager
, vscode-server
, nil
, nixpkgs-unstable
, ... }:
let 
  system = "x86_64-linux";
  pkgsUnstable = import nixpkgs-unstable {
    inherit system;
  };
in
{
  imports = [
    # include NixOS-WSL modules
    nixos-wsl.nixosModules.default
    home-manager.nixosModules.home-manager
    vscode-server.nixosModules.default
    ../../modules/profiles/ca-certs
  ];

  nixpkgs.hostPlatform = {
    inherit system;
  };

  nix.settings.auto-optimise-store = true;

  wsl.enable = true;
  wsl.defaultUser = "scott";
  wsl.extraBin = with pkgs; [
    # Needed for vscode server
    { src = "${coreutils}/bin/uname"; }
    { src = "${coreutils}/bin/dirname"; }
    { src = "${coreutils}/bin/readlink"; }
  ];
  wsl.docker-desktop.enable = true;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Setup VSCode server
  programs.nix-ld.enable = true;
  services.vscode-server.enable = true;
  environment.systemPackages = with pkgs;[
    # Rust
    clang
    llvmPackages_12.bintools
    pkgsUnstable.rustup
    openssl
      
    # Misc

    nodejs_22
    wget
    nil.packages.${system}.nil
    pkgsUnstable.fly
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

  services.postgresql = {
    enable = false;
    initialScript = pkgs.writeText "init-concourse-db" ''
      CREATE USER "concourse";
      CREATE DATABASE "atc" OWNER "concourse";
    '';
  };

  services.concourse-ci = {
    web = {
      enable = false;
      args = {
        session.signing-key = "/home/scott/workplace/concourse-test/session_signing_key";
        tsa.host-key = "/home/scott/workplace/concourse-test/tsa_host_key";
        tsa.authorized-keys = "/run/concourse/worker_key.pub";
        postgres.socket = "/run/postgresql";
        add-local-user = "admin:admin";
        main-team-local-user = "admin";
        external-url = "http://localhost:8080";
      };
    };
    worker = {
      enable = false;
      args = {
        tsa.worker-private-key = "/home/scott/workplace/concourse-test/worker_key";
        tsa.public-key = "/run/concourse/tsa_host_key.pub";
      };
    };
  };

  environment.variables = {
    # https://github.com/rust-lang/rust-bindgen#environment-variables
    LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];

    # Add glibc, clang, glib, and other headers to bindgen search path
    BINDGEN_EXTRA_CLANG_ARGS =
      # Includes normal include path
      (builtins.map (a: ''-I"${a}/include"'') [
        # add dev libraries here (e.g. pkgs.libvmi.dev)
        pkgs.glibc.dev
      ])
      # Includes with special directory paths
      ++ [
        ''-I"${pkgs.llvmPackages_latest.libclang.lib}/lib/clang/${pkgs.llvmPackages_latest.libclang.version}/include"''
        ''-I"${pkgs.glib.dev}/include/glib-2.0"''
        ''-I${pkgs.glib.out}/lib/glib-2.0/include/''
      ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
