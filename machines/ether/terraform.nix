{ ... }:
let
  hostname = "ether";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 510;
    onboot = true;
    domain = "prod.faultymuse.com";
    cores = 16;
    balloon = 16 * 1024;
    memory = 64 * 1024;
    startup = "order=1"; # Run this bad boy as much as possible

    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disk = [
      {
        type = "virtio";
        storage = "nvme";
        size = "4096G";
        discard = true;
      }
      {
        type = "virtio";
        storage = "LTS";
        size = "2048G";
        discard = true;
      }
    ];
  };
}