# Laptop wipe and fresh install

Dedicated project page for wiping the Arch laptop and doing a considered,
side-by-side migration to NixOS - see
[[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]] for the
broader NixOS-side migration work this depends on, and
[[red-sun-whorl-rename-plan|red-sun-whorl rename plan]] for the
hostname/user restructuring that may happen as part of or after this.

## Open decision: rename timing

- [ ] Decide whether the red-sun-whorl rename (hostname + silk/horn user
      split, see [[red-sun-whorl-rename-plan|red-sun-whorl rename plan]])
      happens *during* this wipe (the fresh install boots directly as
      red-sun-whorl) or *after* (install once as x1nano to get a working
      baseline, rename in a later rebuild). Affects the ordering of phase 2
      below.

## Phase 0 - Prerequisites (mostly done, tracked in [[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]])

- [x] flake.nix restructured for multiple hosts
- [x] hosts/x1nano/configuration.nix scaffolded
- [x] hosts/x1nano/BOOTSTRAP.md + bootstrap-install.sh already write the
      destructive partition/LUKS/install flow - phase 2 below just points
      at it, doesn't duplicate it
- [ ] Finish anything still open in
      [[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]] that
      blocks a bootable install (fileSystems/swapDevices placeholders need
      a real `nixos-generate-config` scan, per that file)

## Phase 1 - Full filesystem backup (before touching anything)

Goal: a complete, unfiltered copy of the current Arch install, so nothing
gets missed - separate from and in addition to the already-triaged
arch-reference/ dotfiles capture tracked in
[[dotfiles-and-editor|Dotfiles and editor]] (that one's a curated subset;
this one is the "in case we missed something" net).

- [ ] Pick the portable drive, confirm free space >= used space on the Arch
      install's root (and any separate /home partition) - `df -h` before
      starting
- [ ] Decide backup method:
  - [ ] Option A: `rsync -aAXH --info=progress2` mirror of `/` to the
        drive, excluding pseudo-filesystems (`/proc /sys /dev /tmp /run
        /mnt /media /lost+found`) and the drive's own mountpoint
  - [ ] Option B: raw block-level image (`dd` / `partclone`) of the LUKS
        container as a belt-and-suspenders fallback in addition to A -
        slower and bigger, but bit-for-bit
- [ ] Run the backup, from a live/rescue environment if possible (avoids
      skipping open files, and matches what the actual wipe will see)
- [ ] Verify the backup before wiping anything:
  - [ ] Spot-check `/etc`, `/home/<user>`, `/var/lib`, `~/.config`,
        `~/.ssh`, `~/.gnupg`, and browser profiles exist and are non-empty
        on the copy
  - [ ] Compare total size / file count between source and copy (`du -sh`,
        or `rsync --dry-run` for a diff after the fact)
  - [ ] Confirm the drive is readable from a second machine (or at least
        unmount/remount and re-read) before trusting it as the only copy
- [ ] Only once verified: proceed to phase 2

## Phase 2 - Wipe and fresh install

Mechanics already written up - this phase is "go do that", not new work:

- [ ] Follow hosts/x1nano/BOOTSTRAP.md end to end (USB installer,
      bootstrap-install.sh against the real device, first boot)
- [ ] If renaming to red-sun-whorl during install (see "Open decision"
      above): do the hostname/user-split work first, so
      bootstrap-install.sh and hosts/x1nano/BOOTSTRAP.md target the renamed
      host/config instead of x1nano
- [ ] Follow the general BOOTSTRAP.md steps post-install (secrets, first
      `./bootstrap.sh`, automated post-rebuild check)
- [ ] Verify wifi (including a real captive-portal test), SSH from a
      second session, and anything from
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
