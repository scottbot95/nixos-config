{ config, options, lib, nodes ? {}, ... }:
let
  cfg = config.scott.nixStore;
  mountStr = "${cfg.nfs.server}:${cfg.nfs.export}";
in
{
  options.scott.nixStore = with lib; {
    nfs = {
      enable = mkEnableOption "NFS-mounted /nix directory";
      server = mkOption {
        type = types.str;
        description = "Address of NFS server";
        example = "nas.localdomain";
      };
      export = mkOption {
        type = types.str;
        default = "/nix";
        description = "Exported path from the NFS server to mount";
      };
      extraFsOptions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of extra filesystem options";
      };
    };
  };

  config = lib.mkIf cfg.nfs.enable {
    boot.initrd.supportedFilesystems = [ "nfs" "nfsv4" ];
    boot.initrd.availableKernelModules = [ "nfs" "nfsv4" ];
    boot.initrd.network.enable = true;
    fileSystems."/nix" = {
      device = mountStr;
      fsType = "nfs";
      options = [ "local_lock=all" ] ++ cfg.nfs.extraFsOptions;
      neededForBoot = true;
    };
  };
  #  // (lib.mkIf ((config.deployment.targetEnv ? null) == "proxmox") {
  #   scott.proxmoxGuest.partition = ''
  #     mkdir -p /mnt/nix
  #     # Kinda hacky but w/e. Install image should include nfs-utils I guess?
  #     nix-shell -p nfs-utils --run 'mount.nfs4 ${mountStr} /mnt/nix -o local_lock=all'
  #   '';
  # });
}