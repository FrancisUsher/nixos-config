# Swaylock auth

- [ ] Swaylock fails to unlock even with the correct password entered
      (francis is confident the password was correct). Config itself was
      ported faithfully from arch-reference (see
      [[dotfiles-and-editor|Dotfiles and editor]]'s swaylock item -
      programs.swaylock, ignore-empty-password, Stylix-themed colors), so
      this is a runtime/PAM behavior bug, not a config-content gap. Needs
      reproduction + investigation (check `/etc/pam.d/swaylock`, whether
      NixOS's swaylock module wires PAM correctly, journalctl output from
      a failed unlock attempt).
- [ ] Once the unlock bug above is fixed, add fingerprint auth as an
      alternate unlock method for swaylock (services.fprintd.enable is
      already on for red-sun-whorl per
      [[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]] -
      need to check whether swaylock's PAM stack picks up fprintd
      automatically or needs an explicit pam_fprintd.so line).
