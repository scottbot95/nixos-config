# Homelab

My homelab managed by NixOps. Most machines are Proxmox QEMU VMs.

## Setup instructions
From the root of this repository, run `nix develop` to make all tools needed available.

### Notes on Cross-Compiling
The RaspberryPi uses aarch64 which requires cross-compiling from x86_64.
Theoretically this shouldn't be an issue, however several packages seem to have issues
cross compiling. This can be solved by using a RaspberyPi (or other aarch64 device) as
a [remote build server] with the `--builders 'ssh://hostname aarch64-linux'` command


[remote build server]:https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html