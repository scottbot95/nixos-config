{ lib, ...}:
with lib;
{
  terraform.cloud = {
    hostname = "app.terraform.io";
    organization = "faultymuse-homelab";
    workspaces.name = mkDefault "homelab-infrastructure";
  };
}