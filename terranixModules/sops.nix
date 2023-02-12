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

  module = lib.mapAttrs' (name: vm_config: {
    name = "${name}_deploy_nixos";
    value = lib.mkIf vm_config.enable {
      keys.age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
    };
  }) config.proxmox.qemu;
}