{ config, lib, ... }:
let
  hostname = "netbox";
in
{
  proxmox.qemu.${hostname} = {
    enable = true;
    vmid = 400;
    domain = "lan.faultymuse.com";
    cores = 4;
    memory = 4096;
    startup = "order=4";
    deployment_user = "ops";

    ipconfig0 = "ip=dhcp";
    network = [{
      model = "virtio";
      bridge = "vmbr0";
      tag = 5;
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
