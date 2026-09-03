# Bootstrap (bubu-brain)

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
   - `wifi-secrets.env`:
     ```
     WIFI_PSK="<network password>"
     ```
   - `tailscale-authkey` (expires after 90 days - provision a fresh one at
     https://login.tailscale.com/admin/settings/keys):
     ```
     tskey-auth-...
     ```

3. Run `./bootstrap.sh` - installs the secrets, symlinks `/etc/nixos`, and
   does the first rebuild.

4. Verify SSH/wifi from a second session before closing the first.

# Machine-specific bootstrapping

Some machines need extra steps before the general flow above applies - most
often bringing up a brand new disk from a live installer. See
`hosts/<host>/BOOTSTRAP.md` for a given host, if one exists.
