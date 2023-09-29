{ config, lib, ... }:
let
  hostname = "proxy";
in {
  dns.public.cnames = [ 
    "games"
    "nextcloud"
    # "teslamate"
    "vault"
  ];

  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 300;
    domain = "prod.faultymuse.com";
    cores = 4;
    memory = 4096;
    startup = "order=3,up=15";

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [{
      type = "virtio";
      storage = "nvme";
      size = "20G";
      discard = true;
    }];
  };

  resource.proxmox_vm_qemu.${hostname}.ipconfig0 = "ip=10.0.20.5/24,gw=10.0.20.1";

  module."${hostname}_deploy_nixos".keys = {
    age = "\${data.sops_file.secrets.data[\"sops_key\"]}";
  };
}