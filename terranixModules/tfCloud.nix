{ lib, ...}:
with lib;
{
  terraform.cloud = {
    organization = "faultymuse-homelab";
    workspaces.name = mkDefault "homelab-infrastructure";
  };
}