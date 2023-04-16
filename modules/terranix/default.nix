{ config
, lib
, pkgs
, self # flake
, terranix
, ...
}: 
with lib;
let
  terranixImports = [
    "${terranix}/core/terraform-options.nix" 
    "${terranix}/modules"
    ../../terranixModules
  ];
in
{
  options = {
    terranix = mkOption {
      type = with types; nullOr (deferredModuleWith {
        staticModules = terranixImports; # Only used in docs generation
      });
      description = ''
        Terranix configuration for this machine. 
        May be a struct or function just like any normal module that would be passed to `evalModules`
      '';
      default = null;
    };

    terranixConfig = mkOption {
      type = types.raw;
      description = "Result of `evalModules` on config.terranix";
      visible = false;
      readOnly = true;
    };
  };

  config.terranixConfig =
    let
      filterNotNull = list: builtins.filter (v: v != null) list;
      machineConfigs = filterNotNull (map 
        (machine: machine.config.terranix)
        (builtins.attrValues self.nixosConfigurations));
      terranixConfig = (terranix.lib.terranixConfiguration { 
        inherit pkgs;
        modules = machineConfigs;
      });
    in terranixConfig;
}