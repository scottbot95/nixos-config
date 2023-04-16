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
      type = types.deferredModuleWith {
        staticModules = terranixImports; # Only used in docs generation
      };
      description = ''
        Terranix configuration for this machine. 
        May be a struct or function just like any normal module that would be passed to `evalModules`
      '';
      default = {};
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
      machineConfigs = map 
        (machine: machine.config.terranix)
        (builtins.attrValues self.nixosConfigurations);
    in (terranix.terranixConfiguration { imports = machine; }).config;
}