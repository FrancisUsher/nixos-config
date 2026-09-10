# Dedicated key so bubu-brain can check live state on red-sun-whorl.
{ ... }:

{
  programs.ssh.settings.red-sun-whorl = {
    HostName = "red-sun-whorl";
    User = "silk";
    IdentityFile = "~/.ssh/id_ed25519_red-sun-whorl";
    IdentitiesOnly = "yes";
  };

  programs.ssh.settings.pas-red-sun-whorl = {
    HostName = "red-sun-whorl";
    User = "pas";
    IdentityFile = "~/.ssh/id_ed25519_pas-red-sun-whorl";
    IdentitiesOnly = "yes";
  };
}
