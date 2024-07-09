{ inputs, ... }:
let
  inherit (inputs.nixpkgs.lib)
    filterAttrs
    mapAttrs
    mapAttrs'
    pathExists
    mkDefault
    nixosSystem
    ;
  flakeModules = builtins.attrValues inputs.self.nixosModules;
  dirs = filterAttrs (_: type: type == "directory") (builtins.readDir ./.);
  dirsWithFile = file: filterAttrs (dir: _: pathExists ./${dir}/${file}) dirs;
  nixosConfigurations = mapAttrs (
    name: _:
    nixosSystem {
      modules = flakeModules ++ [
        ./${name}/configuration.nix
        { networking.hostName = mkDefault name; }
      ];
      specialArgs = inputs;
    }
  ) (dirsWithFile "configuration.nix");
  vms = mapAttrs (
    name: machine:
    (machine.extendModules {
      modules = if (builtins.pathExists ./${name}/test.nix) then [ ./${name}/test.nix ] else [ ];
      specialArgs = {
        test = true;
      };
    }).config.system.build.vm
  ) nixosConfigurations;
in
{
  flake = {
    inherit nixosConfigurations vms;
  };

  perSystem = { self', pkgs, system, ...}: {
    packages = 
      let
        machines = pkgs.lib.filterAttrs 
          (_: machine: (machine.pkgs.system == system) && (machine.config.terranix != null)) 
          nixosConfigurations;
        toplevels = builtins.mapAttrs 
          (name: machine: machine.config.system.build.toplevel) 
          machines;
        linkMachines = pkgs.lib.mapAttrsToList (name: toplevel: "ln -s ${toplevel} $out/${name}") toplevels;
        buildAll = derivation {
          inherit system;
          name = "machines";
          PATH = "${pkgs.coreutils}/bin";
          builder = pkgs.writeShellScript "machines" ''
            mkdir -p $out
            ln -s ${self'.packages.terraformConfig} $out/config.tf.json
            ${builtins.concatStringsSep "\n" linkMachines}
          '';
        };
        machinePkgs = mapAttrs' (name: pkg: {
          name = "machines-${name}";
          value = pkg;
        }) toplevels;
      in {
        machines-all = buildAll;
      } // machinePkgs;
  };
}
