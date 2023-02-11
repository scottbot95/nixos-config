# Homelab

My homelab is currently a single [Proxmox VE](https://www.proxmox.com/en/proxmox-ve) node,
plus a single raspberrypi running my DHCP and DNS servers

## Bootstrapping

TODO

## Deploying

Deploy all

```sh
nix run .#terraform -- apply
```

Deploy specific machines
```sh
nix run .#terraform -- apply -target=module.<machine>_deploy_nixos
```
