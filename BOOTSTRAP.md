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

In addition to general nixOS bootstrapping there may be some machine-
specific items that need to be setup before installing the OS.
Those are documented here.

## Thinkpad X1 Nano (laptop)

1. The live installer has no credentials of its own, so it clones via a
   dedicated read-only deploy key instead of your personal one:
   ```
   ssh-keygen -t ed25519 -N "" -f secrets/x1nano-deploy-key -C "x1nano nixos-config deploy key (read-only)"
   ```
   Add `secrets/x1nano-deploy-key.pub` as a Deploy Key on the GitHub repo
   (Settings -> Deploy keys -> Add deploy key) - leave "Allow write access"
   unchecked, this key only needs to read.

   Copy the private half (`secrets/x1nano-deploy-key`, no `.pub`) onto the
   install USB stick (or a second one) - it's not committed to git, so this
   is the only way it leaves this machine.

2. Write the NixOS minimal ISO to a USB stick, boot the laptop from it.

3. Partition (adjust the device name - check with `lsblk` first):
   ```
   parted /dev/nvme0n1 -- mklabel gpt
   parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
   parted /dev/nvme0n1 -- set 1 esp on
   parted /dev/nvme0n1 -- mkpart primary 512MiB 100%

   mkfs.fat -F32 -n boot /dev/nvme0n1p1

   cryptsetup luksFormat /dev/nvme0n1p2
   cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
   mkfs.ext4 -L nixos /dev/mapper/cryptroot

   mount /dev/disk/by-label/nixos /mnt
   mkdir -p /mnt/boot
   mount /dev/disk/by-label/boot /mnt/boot
   ```

4. Generate the hardware profile against the mounted target - this is what
   correctly captures the LUKS mapping as a `boot.initrd.luks.devices` entry:
   ```
   nixos-generate-config --root /mnt
   ```

5. Get the flake onto the machine (needs network - connect via
   `nmcli device wifi connect <ssid> --ask`, or ethernet), using the deploy
   key from step 1 off the USB stick:
   ```
   nix-shell -p git
   mkdir -p ~/.ssh
   cp /path/to/usb/x1nano-deploy-key ~/.ssh/id_ed25519
   chmod 600 ~/.ssh/id_ed25519
   ssh-keyscan github.com >> ~/.ssh/known_hosts

   git clone git@github.com:<you>/nixos-config.git /tmp/nixos-config
   cp /mnt/etc/nixos/hardware-configuration.nix /tmp/nixos-config/hosts/x1nano/hardware-configuration.nix
   ```
   Commit/push that hardware-configuration.nix from a second machine, or
   just proceed - it only needs to exist locally for the install below.

6. Install using this flake instead of the generated stub configuration.nix:
   ```
   nixos-install --root /mnt --flake /tmp/nixos-config#x1nano
   ```
   You'll be prompted to set the initial root password here. Also copy the
   deploy key into the installed system so ongoing `git pull` keeps working
   post-reboot, without it living only in the throwaway live environment:
   ```
   mkdir -p /mnt/home/soong/.ssh
   cp ~/.ssh/id_ed25519 ~/.ssh/known_hosts /mnt/home/soong/.ssh/
   nixos-enter --root /mnt -c '
     chown -R soong:users /home/soong/.ssh
     chmod 700 /home/soong/.ssh
     chmod 600 /home/soong/.ssh/id_ed25519
     chmod 644 /home/soong/.ssh/known_hosts
   '
   ```

7. Reboot into the new system, set soong's login password (`passwd`), then
   follow the bubu-brain steps above from step 1 (clone to `~/nixos-config`,
   drop secrets, run `./bootstrap.sh x1nano`).

8. Verify wifi (including a real captive-portal coffee-shop test - see
   `services.captivePortalAccept`) and SSH from a second session before
   trusting this as your daily system.
