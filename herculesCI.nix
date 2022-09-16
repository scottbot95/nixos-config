# Intentionally not ci.nix to avoid confusion with hercules default ci.nix
{ inputs }:
{ ... }: 
let
  inherit (inputs) nixpkgs flake-utils;
in
{
  ciSystems = [ "x86_64-linux" ];
  onPush.default = {
    outputs = { ... }: flake-utils.lib.eachSystem [ flake-utils.lib.system.x86_64-linux ] (system: 
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # These two attributes will appear in your job for each platform.
        hello = pkgs.hello;
        cow-hello = pkgs.runCommand "cow-hello" {
          buildInputs = [ pkgs.hello pkgs.cowsay ];
        } ''
          hello | cowsay > $out
        '';

      });
  };
}