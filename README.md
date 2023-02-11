# NixOS Configuration

This repository constitutes the NixOS configuration used for my systems managed by Nix flakes.
This repository is published as a convenience for myself as well as a resource for people interested in Nix/NixOS.

## Homelab
The bulk of this repo has to do with the infrastrucutre of my homelab.
See [./homelab.md](./homelab.md) for details

## Creating an ISO

A NixOS installer ISO can be built with:
```
nix build .#nixosConfigurations.$HOST_ISO.config.system.build.isoImage
```

You can then copy the image to a USB stick with:
```
dd if=result/iso/*.iso of=$USB_DEV status=progress
```