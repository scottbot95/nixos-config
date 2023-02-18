{ config, lib, ...}:
let
  extractSecret = secret: "\${data.sops_file.secrets.data[\"${secret}\"]}";
in {
  proxmox = {
    show_deploy_ouptut = false;
    provider = {
      endpoint = "https://pve.faultymuse.com:8006/api2/json";
      # token_id = extractSecret "pm_api.token_id";
      # token_secret = extractSecret "pm_api.token_secret";
      user = extractSecret "pm_api.user";
      password = extractSecret "pm_api.pass";
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

    defaults.lxc = {
      target_node = "pve";
      ostemplate = "local:vztmpl/nixos-system-x86_64-linux.tar.xz";
      flake = toString ../.;
      domain = "lan.faultymuse.com";
      unprivileged = true;

      ssh_public_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICnt0c1V/ZZFW5J3HGqqxDwr6zoq5ouB5uB7IFXxZqdB cardno:18_978_827";

      start = true;
      onboot = true;

      features.nesting = true;

      rootfs = {
        storage = "nvme0";
        size = "8G";
      };
    };
  };
}