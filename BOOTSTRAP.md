# Bootstrap

## Purpose
Most of our machine setup should be stored as declarative config that we can
trust to repeat more or less exactly across installs.
However there are a few steps we need to execute imperatively to bootstrap
that process, kicking it off.

A lot of the bootstrapping process is automated by a script `bootstrap.sh`,
however there will always need to be at least one "manual" step to provision
the bootstrap process with a secret that can be used to kick off the chain
of trust. Right now we have more than one secret.

## Steps

1. Clone repo:
   ```
   git clone <repo-url> ~/nixos-config
   ```

2. Drop these files into `~/nixos-config/secrets/` (gitignored - `bootstrap.sh`
   installs each one to `/etc/<same filename>` with mode 600):
   - `wifi-secrets.env` - only needed on hosts that use
     `networking.wireless.secretsFile` (currently bubu-brain; hosts on
     NetworkManager, like red-sun-whorl, don't consume this file):
     ```
     WIFI_PSK="<network password>"
     ```
   - `tailscale-authkey` (expires after 90 days - provision a fresh one at
     https://login.tailscale.com/admin/settings/keys):
     ```
     tskey-auth-...
     ```

3. Run `./bootstrap.sh` - installs the secrets, symlinks `/etc/nixos`, and
   does the first rebuild. Run it as your normal user, NOT with `sudo` -
   it calls `sudo` itself for the specific steps that need root. Running
   the whole script as root makes `$HOME` resolve to `/root`, so it looks
   for (and installs) the repo and secrets in the wrong place.

4. `bootstrap.sh` finishes by running an automated post-rebuild check
   (sshd active, tailscaled active, network reachable, DNS/HTTPS to
   github.com) and prints a pass/fail summary - a failed check there doesn't
   mean the rebuild failed, just that something's worth a closer look. Still
   keep a second session (another terminal, or SSH in from elsewhere) open
   until you've confirmed you can actually reach this machine - the script
   is running from the same session that might be about to lock you out, so
   it can't fully replace that belt-and-suspenders check.

Some machines need extra steps before the general flow above applies - most
often bringing up a brand new disk from a live installer. See
`hosts/<host>/BOOTSTRAP.md` for a given host, if one exists.
