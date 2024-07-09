{ ...}:
{
  imports = [ 
    ../../modules/profiles/proxmox-guest/v2.nix
  ];

  proxmox.qemuConf = {
    cores = 4;
    memory = 4096;
    bios = "ovmf";
    virtio0 = "local-lvm:vm-9999-disk-0";
  };
  proxmox.qemuExtraConf = {
    ide2 = "local-lvm:vm-9999-cloudinit,media=cdrom";
    template = 1;
  };

  users.users.ops = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  users.users.ops.initialPassword = "";

  services.cloud-init = {
    enable = true;
    network.enable = true;
    settings = {
      system_info = {
        distro = "nixos";
        network.renderers = [ "networkd" ];
        default_user = {
          name = "ops";
        };
      };
      users = [ "default" ];
      manage_etc_hosts = false;
      
      cloud_init_modules = [
        "migrator"
        "seed_random"
        "growpart"
        "resizefs"
        "set_hostname"
      ];

      cloud_config_modules = [
        "disable-ec2-metadata"
        "ssh"
      ];

      # Overwrite default since we need these modules
      cloud_final_modules = [];
    };
  };

  system.stateVersion = "24.05";
}