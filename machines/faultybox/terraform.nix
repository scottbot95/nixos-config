{ config, lib, ... }:
let
  hostname = "faultybox";
in {
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 500;
    clone = "nixos-23.11.20231202.933d7dc";
    domain = "prod.faultymuse.com";
    cores = 8;
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