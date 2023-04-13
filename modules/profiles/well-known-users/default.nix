{config, lib, ...}:
{
  users.users.scott = {
    isNormalUser = true;
    createHome = false;
    home = "/var/empty";
    group = "users";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [./scott.pub];
  };

  security.sudo.extraRules = [
    { users = [ "scott" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}