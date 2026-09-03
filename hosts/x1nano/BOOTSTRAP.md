# Bootstrap (x1nano)

Machine-specific steps for bringing up a brand new X1 Nano install, before
following the general steps in the root `BOOTSTRAP.md`.

The repo is public, so the live installer can clone it with no credentials -
see notes/deploy-key-vs-public-repo.md for why this doesn't need a deploy
key.

## Thinkpad X1 Nano (laptop)

1. Write the NixOS minimal ISO to a USB stick, boot the laptop from it.

2. Connect to the network (needed for cloning the repo and for the install
   itself):
   ```
   nmcli device wifi connect <ssid> --ask
   ```
   (or plug in ethernet).

3. Run `lsblk` and note the disk you're installing onto (e.g. `/dev/nvme0n1`
   - NOT a USB stick). Fetch the installer script and run it against that
   device:
   ```
   nix-shell -p git curl
   curl -LO https://raw.githubusercontent.com/FrancisUsher/nixos-config/master/hosts/x1nano/bootstrap-install.sh
   chmod +x bootstrap-install.sh
   ./bootstrap-install.sh /dev/nvme0n1
   ```
   This is destructive - it partitions, formats, and LUKS-encrypts the given
   device. It shows you `lsblk` output for the device and requires you to
   type the device path back to confirm before touching anything.

   It then generates the hardware profile against the mounted target,
   clones the flake into `/tmp/nixos-config`, drops in the generated
   `hardware-configuration.nix`, and runs `nixos-install` - you'll be
   prompted to set the initial root password.

4. Reboot into the new system, set soong's login password (`passwd`), then
   follow the general steps in the root `BOOTSTRAP.md`, step 1 onward
   (clone to `~/nixos-config`, drop secrets, run `./bootstrap.sh x1nano`).

5. Verify wifi (including a real captive-portal coffee-shop test - see
   `services.captivePortalAccept`) and SSH from a second session before
   trusting this as your daily system.
