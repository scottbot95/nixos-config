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
  };
}