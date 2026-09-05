# Laptop wipe and fresh install

Dedicated project page for wiping the Arch laptop and doing a considered,
side-by-side migration to NixOS - see
[[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]] for the
broader NixOS-side migration work this depends on, and
[[red-sun-whorl-rename-plan|red-sun-whorl rename plan]] for the
hostname/user structure this installs (silk; horn is a separate, still-open
account). The fresh install in phase 2 below boots directly as
red-sun-whorl/silk.

## Phase 1 - Full filesystem backup (before touching anything)

Goal: a complete, unfiltered copy of the current Arch install, so nothing
gets missed - separate from and in addition to the already-triaged
arch-reference/ dotfiles capture tracked in
[[dotfiles-and-editor|Dotfiles and editor]] (that one's a curated subset;
this one is the "in case we missed something" net).

Two ways to do the actual copy. Pick one - don't need both.

### 1a. Simple path: hot backup from the running Arch system

No live USB, no unmounting anything - just rsync the running system to the
drive while it's still your daily driver. The risk (a handful of files
mid-write get skipped or copied inconsistently - browser sqlite dbs, log
files) doesn't matter for a "don't lose a config" safety net; it would
matter for a bootable disk image, which this isn't trying to be. Do this
one unless you specifically want the belt-and-suspenders version in 1b.

- [ ] Confirm free space on the destination drive covers the source:
      ```
      df -h /
      ```
      compare the `Used` column against the drive's free space once it's
      mounted (Arch will auto-mount a plugged-in drive under
      `/run/media/<user>/<label>` via most desktop environments, or mount
      it by hand: `lsblk` to find its device, e.g. `/dev/sdb1`, then
      `sudo mount /dev/sdb1 /mnt` if it isn't already mounted).
- [ ] As root, mirror `/` to the drive, excluding pseudo-filesystems, the
      drive's own mountpoint, and anything already synced there:
      ```
      sudo rsync -aAXH --info=progress2 \
        --exclude={"/proc/*","/sys/*","/dev/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
        / /run/media/<user>/<drive-label>/arch-backup/
      ```
      (swap in the drive's real mountpoint from the `df -h` step above).
      `-aAXH` preserves permissions/ownership/timestamps/ACLs/xattrs and
      hardlinks - the things most likely to matter for a system backup
      and easiest to silently lose with a plain `cp -r`.
- [ ] Skip to "Verify the backup" below.

### 1b. Thorough path: cold backup from a live USB

Boots the laptop off external media first, so the Arch root is fully
unmounted while copied (no open-file skew) - and reuses the same live USB
you're about to make for the actual install in phase 2, so this doesn't
cost you a second USB stick or a second ISO download.

- [ ] Download the NixOS Minimal ISO (x86_64) from
      https://nixos.org/download - any machine, doesn't have to be the
      laptop.
- [ ] Flash it to a USB stick. From a Linux machine (the Arch laptop
      itself is fine - do this before rebooting it):
      ```
      lsblk
      ```
      insert the USB stick, run `lsblk` again, and identify the *new*
      device that appeared - it'll be sized like the USB stick, not the
      internal disk (e.g. `/dev/sdb`, not `/dev/nvme0n1`). Then:
      ```
      sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
      sync
      ```
      (`/dev/sdX`, not a partition like `/dev/sdX1` - `dd` writes the whole
      disk image). Double-check the device path before running this - `dd`
      will silently overwrite whatever you point it at.
- [ ] Boot the laptop from the USB stick (usually a one-time boot-menu key
      at power-on - F12/F10/Esc depending on the machine). You'll land at
      a shell as the `nixos` user with passwordless `sudo`.
- [ ] Identify the internal disk's layout - don't assume, since this isn't
      generated from a known-good scan yet:
      ```
      lsblk -f
      ```
      Look for the root filesystem's partition. If its `FSTYPE` shows
      `crypto_LUKS`, it's encrypted and needs unlocking first:
      ```
      sudo cryptsetup luksOpen /dev/nvme0n1pN cryptroot
      ```
      (`nvme0n1pN` - substitute the actual partition from `lsblk -f`;
      you'll be prompted for the disk's passphrase). This opens it at
      `/dev/mapper/cryptroot`; if it's *not* LUKS, just use the partition
      device directly in the next step instead.
- [ ] Mount it read-only, so the backup can't accidentally modify the
      source:
      ```
      sudo mkdir -p /mnt/arch-root
      sudo mount -o ro /dev/mapper/cryptroot /mnt/arch-root   # or the bare partition if not LUKS
      cat /mnt/arch-root/etc/fstab
      ```
      the `fstab` tells you whether `/boot`, `/home`, or anything else is
      a separate partition needing its own mount under
      `/mnt/arch-root/...` before the backup - mount each one the same
      way (`-o ro`) before continuing.
- [ ] Plug in the portable drive, find its device, and mount it (format it
      first if it's blank - **destructive**, only do this on a drive you
      mean to erase):
      ```
      lsblk
      sudo mkdir -p /mnt/backup
      sudo mount /dev/sdX1 /mnt/backup     # or: sudo mkfs.ext4 -L backup /dev/sdX1  first, if it needs formatting
      ```
- [ ] `rsync` isn't in the minimal ISO's base toolset by default - pull it
      in, then run the copy:
      ```
      nix-shell -p rsync
      rsync -aAXH --info=progress2 --exclude={"lost+found"} \
        /mnt/arch-root/ /mnt/backup/arch-backup/
      ```
      (no `/proc /sys /dev /tmp /run` excludes needed here - they were
      never mounted under `/mnt/arch-root` in the first place, since it's
      a cold, unmounted source this time).
- [ ] Unmount everything cleanly before removing anything:
      ```
      sudo umount /mnt/backup /mnt/arch-root
      sudo cryptsetup luksClose cryptroot   # only if LUKS was opened above
      ```

### Verify the backup (either path)

- [ ] Spot-check `/etc`, `/home/<user>`, `/var/lib`, `~/.config`,
      `~/.ssh`, `~/.gnupg`, and browser profiles exist and are non-empty
      on the copy
- [ ] Compare total size between source and copy:
      ```
      du -sh /            # or /mnt/arch-root, for the live-USB path
      du -sh <backup-destination>
      ```
      sizes won't match exactly (pseudo-filesystems excluded, and the
      backup destination itself adds nothing back) but should be in the
      same ballpark - a wildly smaller copy means something didn't get
      copied.
- [ ] Confirm the drive is readable from a second machine (or at least
      unmount/remount and re-read it) before trusting it as the only copy
- [ ] Only once verified: proceed to phase 2

## Phase 2 - Wipe and fresh install

Mechanics already written up - this phase is "go do that", not new work:

- [ ] Follow hosts/red-sun-whorl/BOOTSTRAP.md end to end (USB installer,
      bootstrap-install.sh against the real device, first boot, fingerprint
      enrollment)
- [ ] Follow the general BOOTSTRAP.md steps post-install (secrets, first
      `./bootstrap.sh`, automated post-rebuild check)
- [ ] Verify wifi (including a real captive-portal test), SSH from a
      second session, sudo via fingerprint (`fprintd-enroll`, then
      `sudo -k && sudo true`), and anything from
      [[nixos-rebuild-health-checks|Post-rebuild health checks]] worth
      running by hand before trusting this as the daily system

## Phase 3 - Backup triage (the meticulous walk-through)

Goal: work through the full backup from phase 1 together, a bit at a time,
until nothing's left unaccounted for. Three-way decision per item:

- **Clear** - not needed, reproduced by nothing, just delete it from the
  backup
- **Roll in** - port it into nixos-config (a home-manager module, a system
  module, a dotfile) the way [[dotfiles-and-editor|Dotfiles and editor]]
  already does for the curated arch-reference/ set - once ported *and
  verified working* on the new install, delete it from the backup
- **Archive** - not worth reproducing declaratively but not safe to throw
  away either (old project files, one-off scripts, media) - move it into a
  dedicated backup-archive directory instead of leaving it buried in the
  full-system mirror

Mechanics:

- [ ] Create the backup-archive directory (top-level, on the portable
      drive or wherever long-term cold storage for this lives) before
      starting triage, so "archive" has somewhere to land immediately
      instead of piling up as a TODO
- [ ] Decide a walk order - suggest by top-level directory (`/etc`,
      `/home/<user>`, `/usr/local`, `/opt`, `/var/lib`, ...) sized biggest
      first (`ncdu`, or `du -sh /* | sort -rh`) so the highest-value/
      highest-risk stuff gets attention early rather than last
- [ ] Work through each top-level directory: for every item inside, apply
      the three-way decision above; check the directory off once it's
      fully triaged (empty, or reduced to only things intentionally
      staying as archive)
- [ ] Cross-reference open items in [[dotfiles-and-editor|Dotfiles and
      editor]] and [[migrate-arch-laptop-to-nixos|Migrate Arch laptop to
      NixOS]] while triaging - anything found in the backup that maps to
      an already-tracked "port X config" item should close that loop
      instead of creating a duplicate one
- [ ] Done when the full-system mirror from phase 1 is empty (everything
      cleared, rolled in, or moved to the archive directory) - at that
      point the archive directory is the only surviving copy of the old
      Arch install, and the portable drive can be repurposed
