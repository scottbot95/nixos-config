{ ... }:
let
  hostname = "game-status-ui";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 600;
    clone = "nixos-24.05.20240704.c0d0be0";
    domain = "prod.faultymuse.com";
    cores = 4;
    memory = 2 * 1024;
    startup = "order=5";
    deployment_user = "ops";

    ipconfig0 = "ip=dhcp";
    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 20;
      firewall = false;
    }];

    disks.ide.ide2.cloudinit = {
      storage = "local-lvm";
    };
    disks.virtio.virtio0.disk = {
      storage = "nvme";
      size = "20G";
      discard = true;
    };
  };
}