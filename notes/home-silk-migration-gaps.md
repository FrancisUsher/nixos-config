# home/silk migration gaps

Found while reviewing `/mnt/backup-ssd/arch-backup-2026-09-03/home/silk/`
for things that were never even pulled into `arch-reference/` in the first
pass. See [[dotfiles-and-editor|Dotfiles and editor]] for what's already
ported.

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
      separately. Backup path: `home/silk/keymap-remap.hwdb`.
