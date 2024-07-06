{ ... }:
{
  imports = [
    ./default.nix
  ];

  # Let ops account import unsigned NARs (eg not from cache.nixos.org)
  # TODO maybe we can start signing NARs and add the key?
  nix.settings.trusted-users = [
    "ops"
  ];

  networking = {
    useNetworkd = true;
    dhcpcd.enable = false;
    interfaces.ens18.useDHCP = true;
  };

  systemd.network.enable = true;

  users.mutableUsers = false;

  # Disable login of root account
  users.users.root.hashedPassword = "!";
  users.users.root.initialPassword = null; # reset this to null to avoid conflicts with v1

  # User for performing deployments
  users.users.ops = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # Enabled passwordless sudo for ops account
  security.sudo.extraRules = [{ 
    users = [ "ops" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}