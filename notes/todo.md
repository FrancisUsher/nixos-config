# Todo

- [ ] home-manager-soong.service fails on bubu-brain during `dconfSettings`
      activation (`GDBus.Error: ServiceUnknown: The name is not
      activatable`) - likely a GTK-related home-manager module (pulled in
      via qutebrowser/fuzzel/sway, meant for red-sun-whorl's desktop)
      trying to write dconf settings on bubu-brain, which is headless
      (autologin getty, no D-Bus session bus). Was previously masked by
      the ~/.ssh/config clobber failing first.
- [ ] [[bubu-brain-hardware-module|bubu-brain hardware module]]
- [ ] [[ql600-network-print-server|QL-600 raw print queue: verify real end-to-end print with Brother's driver]]
- [ ] [[dotfiles-and-editor|Dotfiles and editor]]
- [ ] [[remote-desktop|Remote desktop]]
- [ ] [[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]]
- [ ] [[claude-code-guardrails|Claude Code guardrails]]
- [ ] [[tmux-session-persistence|tmux session persistence across reboots]]
- [ ] [[things-to-investigate|Things to investigate]]
- [ ] [[bubu-brain-hardware|bubu-brain hardware]]
- [ ] [[nixos-rebuild-health-checks|Post-rebuild health checks]]
- [ ] [[laptop-wipe|Laptop wipe and fresh install]]
- [ ] [[notes-cleanup|Notes cleanup: prune completed checkboxes]]
- [ ] [[build-warnings|Build warnings to clean up]]
- [ ] [[hotkey-overlay-followups|Hotkey overlay follow-ups]]
- [ ] [[swaylock-auth|Swaylock auth]]
- [ ] [[dotfiles-migration-gaps|Dotfiles migration gaps]]
- [ ] [[home-silk-migration-gaps|home/silk migration gaps]]
- [ ] [[thinkpad-power-script|ThinkPad power script]]
- [ ] Check out agarrharr/awesome-cli-apps (surfaced from an old Arch
      todo.txt found on backup-ssd, never actually done)
- [ ] Make a nice TUI dashboard - `dev/power-tui` on backup-ssd already has
      some WIP on this idea, worth reviewing before starting fresh (surfaced
      from the same old todo.txt)
- [ ] Verify audio actually works properly on red-sun-whorl (surfaced from
      the same old todo.txt - was still an open question on the Arch install)
- [ ] Learn Sway hotkeys properly / get more fluent with them (surfaced from
      the same old todo.txt)
- [ ] Secondary fuzzel/dmenu launcher on its own hotkey, scoped to a
      curated set of desktop entries (nvim, htop, etc.) hidden from the
      main launcher via `xdg.desktopEntries.*.noDisplay` in
      modules/programs/fuzzel.nix
- [ ] Investigate whether sops-nix is worth adopting for secrets (currently
      using plain out-of-store files like /etc/cloudflare-dns-token.env,
      /etc/wifi-secrets.env, /etc/tailscale-authkey)
