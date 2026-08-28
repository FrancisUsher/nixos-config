# Bootstrap (bubu-brain)

Manual, one-time steps required before this flake can manage itself.
Automated by `bootstrap.sh` except dropping the secrets in place.

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
   - `tailscale-authkey` (expires after 90 days - mint a fresh one at
     https://login.tailscale.com/admin/settings/keys):
     ```
     tskey-auth-...
     ```

3. Run `./bootstrap.sh` - installs the secrets, symlinks `/etc/nixos`, and
   does the first rebuild.

4. Verify SSH/wifi from a second session before closing the first.

Later rebuilds: `sudo nixos-rebuild switch`.
