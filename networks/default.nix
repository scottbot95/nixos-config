{ 
  inputs,
  extraArgs,
  subDirs,
  pkgs,
  lib,
  nixosModules,
  ...
}:
let
  moduleDirs = builtins.map (d: ./modules/${d}) (subDirs ./modules);
  defaults = {
    # TODO the sops import should theoreticlly be possible in the sops module but is not possible
    # due to nixops
    imports = 
      (builtins.attrValues nixosModules) ++ 
      moduleDirs ++ 
      (with inputs; [ 
        sops-nix.nixosModules.sops
        hercules-ci-agent.nixosModules.agent-profile
      ]);
    _module.args = extraArgs;
  };
  networkDirs = builtins.filter (d: d != "modules" ) (subDirs ./.);
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
    networkDirs;
  networks = builtins.listToAttrs networkList;
in networks // {
  default = networks.homelab;
}