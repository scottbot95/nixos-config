{ ... }:
let
  hostname = "faulty-trader";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 511;
    domain = "prod.faultymuse.com";
    clone = "nixos-24.05.20240704.c0d0be0";
    cores = 4;
    memory = 4 * 1024;
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