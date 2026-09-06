# home/silk migration gaps

Found while auditing `/mnt/backup-ssd/arch-backup-2026-09-03/home/silk/` for
things that were never even pulled into `arch-reference/` in the first pass.
See [[dotfiles-and-editor|Dotfiles and editor]] for what's already ported.

This audit is partial - see the last item below for what's left to look at.

- [ ] `.zshenv` was never ported - two real settings:
      `PATH=(~/.local/bin ~/.npm-global/bin $PATH)` and
      `QT_QPA_PLATFORM=wayland` (forces Krita to run natively on Wayland
      instead of XWayland). Backup path:
      `home/silk/.zshenv`.
- [ ] `icat` alias (`kitten icat`) - the zsh port deliberately deferred
      this "until kitty itself is ported" (see
      [[dotfiles-and-editor|Dotfiles and editor]]'s zsh item). Kitty's
      been ported since; the alias never got added. Backup path:
      `home/silk/.bashrc` (line: `alias icat='kitten icat'`).
- [ ] `run-zmk.zsh` - a devcontainer-based ZMK firmware build workflow
      (`devcontainer up --workspace-folder ~/dev/zmk`, then `docker exec`
      into it). `zmk.ini` itself got ported; this build workflow didn't.
      Backup path: `home/silk/run-zmk.zsh`.
- [ ] `keymap-remap.hwdb` - a stub hwdb file for remapping keys on the
      ThinkPad X1 Nano keyboard (header comment only, no actual rules
      were ever written). Distinct from
      [[dynamic-keymaps-utility|Dynamic keymaps utility]] (that's a
      cheat-sheet display tool; this is static hardware-level
      remapping) - signals old unfinished intent worth picking up
      separately. Backup path: `home/silk/keymap-remap.hwdb`. An old
      `.todo/todo.txt` on the same backup also had "read
      Alekamerlin/keyboard-remap-guide" and "make a command to show secret
      fn shortcuts" as open items - both relevant context for whenever this
      gets picked up.
- [ ] Finish auditing `home/silk` - only the dotfiles-shaped parts have been
      looked at closely so far. Still unreviewed: `.config/{chromium, dconf,
      kritarc, kritadisplayrc, nvim.bkp, procps, pulse, QtProject.conf,
      tailscale}`, and top-level `.bash_history`, `.bash_logout`,
      `.bash_profile`, `.bashrc`, `.cargo`, `.claude`/`.claude.json`,
      `container_hist.txt`, `dev/` (actual project repos - e.g. `power-tui`,
      `themer`, several `zmk-*` firmware forks - a different kind of review
      than dotfiles, whether they're pushed/backed up elsewhere rather than
      config to port), `Downloads`, `.gemini`, `.histfile`, `.inxi`,
      `.lesshst`, `.local/share` (most of this backup's 2.9G lives here,
      unreviewed), `.pulse-cookie`, `to-add.txt` (now stale - referenced the
      since-deleted `.dotfiles` bare repo), `.wget-hsts`, `.wordgrinder`,
      `.zcompdump`. `etc/` and `var/` at the top of the backup were checked
      and ruled out - stock Arch/etckeeper system files with no NixOS
      equivalent to port, same conclusion the old `system-config/collect.zsh`
      review already reached.
