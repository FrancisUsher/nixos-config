# Todo

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
- [ ] [[git-sync-check-hosts|Sync check-hosts.sh via git instead of rsync]]
- [ ] [[laptop-wipe|Laptop wipe and fresh install]]
- [ ] [[hotkey-overlay-followups|Hotkey overlay follow-ups]]
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
- [ ] Refine red-sun-whorl's wallpaper aesthetic further
      (modules/themes/red-sun-whorl-wallpaper.nix) - current sun-line/ridges
      scene is an acceptable first pass, not a final look
- [ ] Procedural window borders: more generators, ornamentation, theming (#15)
- [ ] [[red-sun-whorl-seamless-startup|Seamless themed startup process for red-sun-whorl]]
- [ ] Better terminal autocomplete for command params/flags (had this on
      the old Arch machine) - research the best way to set it up on NixOS
- [ ] Review and flesh out the full zsh setup - first-time setup was
      aborted early due to time constraints, worth revisiting properly
- [ ] Fix brightness keys (XF86MonBrightnessUp/Down) on red-sun-whorl - not
      working; pre-existing, unrelated to the Hyprland hyprlang-to-Lua
      migration (confirmed the binds themselves survived that migration
      unchanged)
- [ ] Make fingerprint recognition on red-sun-whorl more reliable /
      tolerant of finger position (#14)
- [ ] waybar network/battery icons are empty strings in waybar.nix (format-wifi,
      format-charging, format-icons, etc.) - glyphs were lost at some point, so
      wifi shows nothing and battery shows just the number
- [ ] Set up a ~/.cache pruning rule (e.g. home-manager
      systemd.user.tmpfiles.rules) so stale files from dropped features don't
      linger - check what lives in ~/.cache that isn't disposable first
      (cliphist history, border-harness live.lua)
