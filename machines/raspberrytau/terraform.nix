{ config, lib, terranix-proxmox, self, ...}:
let
  machine = baseNameOf ./.;
in
{
  data.sops_file.tau_secrets = {
    source_file = toString ./secrets.yaml;
  };

  module."${machine}_deploy_nixos" = {
    source = terranix-proxmox.inputs.terraform-nixos;
    build_on_target = true;
    flake = toString self;
    flake_host = machine;
    target_host = "192.168.4.2";
    target_user = "root";
    ssh_private_key = "\${data.sops_file.tau_secrets.data[\"ssh.priv_key\"]}";
    ssh_agent = false;
  };
}