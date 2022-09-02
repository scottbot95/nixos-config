{
    network = {
        description = "Basic Proxmox NixOps Network";
        storage.legacy = {};
    };

    trivial = import ./vms/trivial-proxmox.nix;
}