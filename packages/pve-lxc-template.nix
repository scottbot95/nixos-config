{ pkgs,
  inputs,
 ...
}:
let
  nixosConfig = { modulesPath,...}: {
    imports = [
      "${modulesPath}/virtualisation/proxmox-lxc.nix"
    ];

    environment.systemPackages = with pkgs; [
      jq
    ];

    users.users.root.initialPassword = "";

    system.stateVersion = "23.05";
  };
in 
inputs.nixos-generators.nixosGenerate {
  inherit pkgs;
  format = "proxmox-lxc";
  modules = [ nixosConfig ];
}