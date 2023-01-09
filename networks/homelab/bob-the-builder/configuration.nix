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

  scott.sops.enable = true;
  
  scott.concourse = {
    enable = true;
    externalUrl = "http://bob-the-builder.lan.faultymuse.com:8080";
    encryptionKey = "services/concourse/encryption_key";
    gitHubAuth = {
      clientId = "services/concourse/gh_client_id";
      clientSecret = "services/concourse/gh_client_secret";
      mainTeamUsers = [ "scottbot95" ];
    };
  };

  sops.secrets."services/concourse/encryption_key" = {};
  sops.secrets."services/concourse/gh_client_id" = {};
  sops.secrets."services/concourse/gh_client_secret" = {};

  networking.firewall.allowedTCPPorts = [ 8080 ];

  system.stateVersion = "22.05";
}