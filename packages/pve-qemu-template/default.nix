{ inputs,
  ...
}: inputs.nixos-generators.nixosGenerate {
  system = "x86_64-linux";
  format = "proxmox";
  modules = [ ./configuration.nix ];
}