# Dedicated key so bubu-brain can check live state on red-sun-whorl.
{ ... }:

{
  programs.ssh.settings.red-sun-whorl = {
    HostName = "red-sun-whorl";
    User = "silk";
    IdentityFile = "~/.ssh/id_ed25519_red-sun-whorl";
    IdentitiesOnly = "yes";
  };
}
