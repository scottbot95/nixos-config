{config, lib, pkgs, inputs, ...}:
{
  deployment.proxmox = {
    cores = 16;
    memory = 8192;
    startOnBoot = true;
    disks = [{
      volume = "nvme0";
      size = "100G";
      enableSSDEmulation = true;
      enableDiscard = true;
    }];
    network = [{
      bridge = "vmbr0";
      tag = 5;
    }];
  };

  scott.sops.enable = false;

  scott.concourse = {
    enable = true;
    externalUrl = "http://bob-the-builder.lan.faultymuse.com:8080";
  };

  environment.systemPackages = [ inputs.self.packages.${pkgs.system}.nixops];

  networking.firewall.allowedTCPPorts = [ 8080 ];

  system.stateVersion = "22.05";
}