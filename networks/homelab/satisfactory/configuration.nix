{ config, lib, nodes, ... }:
let 
in
{
  # TODO figure out how to make NFS store work
  scott.nixStore.nfs.enable = false;
  scott.nixStore.nfs.server = nodes.nas.config.networking.fqdn;

  scott.games.server.satisfactory.enable = true;
  scott.games.server.satisfactory.listenAddress = "0.0.0.0";

  # scott.proxmoxGuest.partition = ''
  #   mkdir -p /mnt/nix
  #   # Kinda hacky but w/e. Install image should include nfs-utils I guess?
  #   nix-shell -p nfs-utils --run 'mount.nfs4 ${nodes.nas.config.networking.fqdn}:/nix /mnt/nix -o local_lock=all'
  # '';

  deployment.proxmox = {
    cores = 8;
    memory = 8192;
    startOnBoot = true;
    disks = [{ 
      volume = "nvme0";
      size = "50G";
      enableSSDEmulation = true;
      enableDiscard = true;
    }];
    network = [{
      bridge = "vmbr0";
      tag = 20;
    }];
  };

  networking.domain = "prod.faultymuse.com";

  fileSystems."/var/lib/satisfactory" = {
    device = "${nodes.nas.config.networking.fqdn}:/data/satisfactory";
    fsType = "nfs";
  };

  system.stateVersion = "22.05";
}