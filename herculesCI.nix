# Intentionally not ci.nix to avoid confusion with hercules default ci.nix
{ self, inputs }:
{ branch, ... }: 
let
  inherit (inputs) nixpkgs flake-utils hercules-ci-effects;
in
{
  ciSystems = [ "x86_64-linux" ];
  onPush.default = {
    outputs = { ... }: flake-utils.lib.eachSystem [ flake-utils.lib.system.x86_64-linux ] (system: 
      let
        pkgs = import nixpkgs {
          overlays = [
            hercules-ci-effects.overlay
          ];
        };
      in {
        effects = {
          deploy-homelab = pkgs.effects.runIf /*(branch == "master")*/ false (
            pkgs.effects.runNixOps2 {
              flake = self;
              prebuildOnlyNetworkFiles = [ "networks/prebuild-stub.nix" ];
              # action = "dry-run";
              extraDeployArgs = [
                "--exclude" "bob-the-builder" "raspberrytau"
              ];
            }
          );
        };
      });
  };
}