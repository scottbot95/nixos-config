let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
  inherit (lock.nodes.nixops-proxmox.locked) owner repo rev narHash;
  nixops-proxmox-src = builtins.fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    sha256 = narHash;
  };
  nixops-proxmox = import nixops-proxmox-src {};
in
{
  defaults = { lib, ...}:
  with lib; {
    imports = [ "${nixops-proxmox}/lib/python3.10/site-packages/nixops_proxmox/nix/proxmox.nix" ];
  };
}