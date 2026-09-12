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
- [ ] [[notes-cleanup|Notes cleanup: prune completed checkboxes]]
- [ ] [[build-warnings|Build warnings to clean up]]
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
- [ ] Migrate red-sun-whorl's Hyprland config from hyprlang to Lua
      (modules/programs/hyprland.nix, `configType = "hyprlang"`) - Hyprland
      warns on startup that hyprlang is deprecated as of 0.55
      (https://wiki.hypr.land/Configuring/Start/: "Since Hyprland 0.55,
      hyprlang is deprecated in favor of lua"). Needs research into whether
      home-manager's hyprland module supports `configType = "lua"` yet and
      what the settings-attrset-to-Lua translation looks like.
