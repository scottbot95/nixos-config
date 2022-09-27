let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  inherit (lock.nodes.nixops-proxmox.locked) owner repo rev narHash;
  nixops-proxmox = builtins.fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    sha256 = narHash;
  };
in
{
  defaults = { lib, ...}:
  with lib; {
    imports = [ "${nixops-proxmox}/nixops_proxmox/nix/proxmox.nix" ];
  };
}