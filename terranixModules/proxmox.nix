{ config, lib, ...}:
let
  extractSecret = secret: "\${data.sops_file.secrets.data[\"${secret}\"]}";
in {
  proxmox = {
    show_deploy_ouptut = false;
    provider = {
      endpoint = "https://pve.faultymuse.com:8006/api2/json";
      token_id = extractSecret "pm_api.token_id";
      token_secret = extractSecret "pm_api.token_secret";
      log_level = "debug";
    };

    defaults.qemu = {
      agent = true;
      target_node = "pve";
      flake = toString ../.;
      clone = "nixos-23.05.20230127.8a828fc";
      full_clone = true;
      bios = "ovmf";
      os_type = "cloud-init";
      onboot = true;
    };
  };
}