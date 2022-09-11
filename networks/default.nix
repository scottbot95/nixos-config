{ inputs, extraArgs, subDirs, pkgs, lib, nixosModules, ... }:
let
  defaults = {
    # TODO the sops import should theoreticlly be possible in the sops module but is not possible
    # due to nixops
    imports = builtins.attrValues nixosModules ++ [ inputs.sops-nix.nixosModules.sops ];
    _module.args = extraArgs;
  };
  networkList = builtins.map
    (name: 
      let
        # TODO if I were using scopes right, I think we shouldn't need extraArgs here
        networkConfig = builtins.removeAttrs (pkgs.callPackage ./${name} (extraArgs // { inherit extraArgs; })) [ "override" "overrideDerivation" ];
      in {
        inherit name;
        value = networkConfig // {
          inherit (inputs) nixpkgs;
          defaults = defaults // (networkConfig.defaults or {});
        };
      })
    (subDirs ./.);
  networks = builtins.listToAttrs networkList;
in networks // {
  default = networks.homelab;
}