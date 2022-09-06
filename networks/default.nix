{ inputs, extraArgs, subDirs, pkgs, lib, nixosModules, ... }:
let
  defaults = {
    # inherit nixpkgs;
    imports = builtins.attrValues nixosModules;
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