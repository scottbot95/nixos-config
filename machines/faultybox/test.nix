{config, lib, modulesPath, ...}:
let
  httpPort = config.services.faultybox.port;
  httpsPort = 8443;
in {
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];
  services.faultybox.address = lib.mkForce "0.0.0.0";

  services.promtail.enable = lib.mkForce false;

  networking.firewall.allowedTCPPorts = [httpPort];

  virtualisation.graphics = false;
  virtualisation.forwardPorts = [
    { from = "host"; host.port = httpPort; guest.port = httpPort; }
    { from = "host"; host.port = httpsPort; guest.port = httpsPort; }
  ];
}