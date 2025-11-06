{ config, lib, ...}:
{
  terraform.required_providers = {
    sops = {
      source = "carlpett/sops";
      version = "0.7.2";
    };
  };

  provider.sops = {};

  data.sops_file.secrets = {
    source_file = "secrets/homelab.yaml";
  };

  module = 
    let 
      addSopsKeys = type: 
        lib.mapAttrs' (name: vm_config: {
          name = "${name}_deploy_nixos";
          value = lib.mkIf vm_config.enable {
            keys.age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
          };
        }) type;
    in
      lib.mkMerge [
        (addSopsKeys config.proxmox.qemu)
        (addSopsKeys config.proxmox.lxc)
      ];
}