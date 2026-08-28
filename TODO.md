# TODO

## Home Manager (foundational - enables everything below it)
- [x] Set up Home Manager as a flake input

## Dotfiles / editor (depends on Home Manager)
- [x] Triage arch-reference/, prune junk before deciding what's worth converting
- [ ] Port hypr config
- [ ] Port sway config
- [ ] Port swaylock config
- [ ] Port waybar config
- [ ] Port fuzzel config
- [ ] Port kitty config
- [ ] Port zsh config (.zshrc + .config/zsh)
- [ ] Port oh-my-posh config (or replace with starship - see QoL tools below)
- [ ] Port fastfetch config
- [ ] Port gh config
- [ ] Port gitui config
- [ ] Port go config
- [ ] Port uv config
- [ ] Port kicad config
- [ ] Port zmk (keyboard firmware) config
- [ ] Port glow config
- [ ] Port qutebrowser config
- [ ] Reproduce custom theming scripts (themer/, themes/)
- [ ] Review system-config/collect.zsh - old Arch dotfiles-workflow experiment,
      list of /etc files it tracked may be useful as a checklist
- [ ] Import orgfiles/ into a nvim-orgmode setup
- [ ] Install neovim via Home Manager
- [ ] Migrate nvim config from Arch laptop
- [ ] Add obsidian.nvim, start using it for notes
- [ ] tmux keybind remap (closer to Sway's mental model)
- [ ] git config
- [ ] Other QoL tools worth considering: starship, direnv, fzf, atuin

## GitHub CLI (independent - doesn't need Home Manager)
- [ ] Install `gh`
- [ ] Authenticate without a local browser (device-code flow, entering the
      code on phone/laptop, or a PAT via `gh auth login --with-token`)

## Remote desktop (independent, bigger project - own future branch)
- [ ] Sway + wayvnc, bound to tailscale0 only
- [ ] Display manager / headless compositor launch + session lifecycle
- [ ] Audio (pipewire) and clipboard passthrough

## Migrate Arch laptop to NixOS (big project, depends on Home Manager)
- [ ] Restructure flake.nix for multiple hosts (shared modules + per-host config)
- [ ] Laptop hardware-configuration.nix
- [ ] WiFi: NetworkManager instead of static wireless.networks (roaming)
- [ ] Power management (TLP/battery, backlight)
- [ ] Sway desktop config, ported from current Arch setup
- [ ] Home Manager config shared between bubu-brain and laptop

## Claude Code guardrails (unrelated to nixos-config)
- [ ] Set up predictable guardrails for git usage etc (settings.json
      permissions/hooks) so it doesn't do unpredictable things
