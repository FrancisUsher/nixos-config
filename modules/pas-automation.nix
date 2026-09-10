{ authorizedKeyFiles }:
{ pkgs, ... }:

{
  users.users.pas = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    shell = pkgs.bash;
    openssh.authorizedKeys.keyFiles = authorizedKeyFiles;
  };

  security.sudo.extraRules = [
    {
      users = [ "pas" ];
      commands = [
        { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
