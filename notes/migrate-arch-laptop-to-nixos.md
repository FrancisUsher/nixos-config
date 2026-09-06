---
id: migrate-arch-laptop-to-nixos
aliases: []
tags: []
---
# Migrate Arch laptop to NixOS

Big project.

- [ ] Finish migrating data off the Arch install - use the backup ssd mounted
      /mnt/backup-ssd/arch-backup-2026-09-03
- [ ] Power management: TLP now on by default via nixos-hardware; backlight
      and any further battery tuning still open
- [ ] Sway desktop config, ported from current Arch setup
- [ ] Split home.nix into shared + per-host pieces - see [[red-sun-whorl-rename-plan|red-sun-whorl rename plan]]
      for why this isn't just a themed variant of bubu-brain's setup
