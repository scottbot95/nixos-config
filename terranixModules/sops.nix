{...}:
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
}