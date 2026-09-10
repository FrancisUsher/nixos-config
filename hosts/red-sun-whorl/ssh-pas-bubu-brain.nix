{ ... }:

{
  programs.ssh.settings.pas-bubu-brain = {
    HostName = "bubu-brain";
    User = "pas";
    IdentityFile = "~/.ssh/id_ed25519_pas-bubu-brain";
    IdentitiesOnly = "yes";
  };
}
