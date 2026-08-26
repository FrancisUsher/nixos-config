# Bootstrap (bubu-brain)

Manual, one-time steps required before this flake can manage itself.
Automated by `bootstrap.sh` except the secrets step.

1. Clone repo:
   ```
   git clone <repo-url> ~/nixos-config
   ```

2. Create `/etc/wifi-secrets.env` (not tracked in git):
   ```
   WIFI_PSK="<network password>"
   ```
   ```
   sudo install -m 600 /dev/stdin /etc/wifi-secrets.env <<< 'WIFI_PSK="..."'
   ```

3. Point `/etc/nixos` at the repo (remove existing real dir first, `ln -s` nests into an existing dir otherwise):
   ```
   sudo rm -rf /etc/nixos
   sudo ln -s ~/nixos-config /etc/nixos
   ```

4. First rebuild (flakes not yet enabled system-wide):
   ```
   sudo nixos-rebuild switch --flake ~/nixos-config#bubu-brain --option experimental-features "nix-command flakes"
   ```
   Later rebuilds: `sudo nixos-rebuild switch`.

5. Verify SSH/wifi from a second session before closing the first.
