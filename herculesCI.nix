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
        excludeMachines = [ "bob-the-builder" "ns2" "public-ns" ];
      in {
        effects = {
          deploy-homelab = pkgs.effects.runIf /*(branch == "master")*/ true (
            pkgs.effects.runNixOps2 {
              flake = self // {
                nixopsConfigurations.default = 
                  let 
                    trimmedNetwork = builtins.removeAttrs self.nixopsConfigurations.default excludeMachines;
                  in
                    trimmedNetwork;
              };
              prebuildOnlyNetworkFiles = [ ./networks/prebuild-stub.nix ];
              action = "dry-run";
              makeAnException = "I know this can corrupt the state, until https://github.com/NixOS/nixops/issues/1499 is resolved.";
              extraDeployArgs = [ "--exclude" ] ++ excludeMachines;
            }
          );
        };
      });
  };
}