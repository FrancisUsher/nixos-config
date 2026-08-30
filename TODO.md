# TODO

## Questions
- [ ] I noticed we used nixos-hardware to provision the thinkpad. I wonder if
      we can define a similar module for our SFFPC which is what bubu-brain
      is currently hosted on?

## Bootstrap improvements
- [ ] I made some manual changes to the files to improve clarity and writing
      style. please review.
- [ ] "verify ssh/wifi" but presumably we're already connected to wifi because
      we just used git clone on a github repo. Anyway I think this verification
      should be scripted, not in the MD file.
- [ ] I don't know if I really like the idea of having my deploy key be
      dependent on github and github auth. If we do want this "deploy keys"
      feature we need to talk through what they are, pros/cons, alternatives.
- [ ] There looks like a lot of stuff in the machine-specific setup that could
      be delegated to a script instead of written out in the MD file.
- [ ] I'm thinking we might just want to split out the bootstrapping MD files
      into separate ones for each purpose. So, some global bootstrapping in the
      root dir; but then some machine-specific bootstrpping in the hosts dirs.

## Home Manager (foundational - enables everything below it)
- [x] Set up Home Manager as a flake input

## Dotfiles / editor (depends on Home Manager)
- [x] Triage arch-reference/, prune junk before deciding what's worth converting
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

## bubu-brain hardware
- [ ] Verify acpi_enforce_resources=lax (hosts/bubu-brain/rgb.nix) actually
      fixes RAM RGB staying off after a real cold power off/on - added
      after RAM lit back up post power cycle, only tested via warm reboot
      so far

## GitHub CLI (independent - doesn't need Home Manager)
- [ ] Install `gh`
- [ ] Authenticate without a local browser (device-code flow, entering the
      code on phone/laptop, or a PAT via `gh auth login --with-token`)

## Remote desktop (independent, bigger project - own future branch)
- [ ] Sway + wayvnc, bound to tailscale0 only
- [ ] Display manager / headless compositor launch + session lifecycle
- [ ] Audio (pipewire) and clipboard passthrough

## Migrate Arch laptop to NixOS (big project, depends on Home Manager)
- [x] Restructure flake.nix for multiple hosts (shared modules + per-host config)
- [x] hosts/x1nano/configuration.nix scaffolded (unbootable until hardware
      config is added - see below)
- [x] WiFi: NetworkManager instead of static wireless.networks (roaming)
- [x] Headless captive-portal wifi login (modules/captive-portal.nix,
      services.captivePortalAccept, wired into x1nano)
- [x] hosts/x1nano/hardware-configuration.nix preview - generated via
      nixos-generate-config --no-filesystems while still on Arch (kernel
      modules, CPU microcode). fileSystems/LUKS still pending the real
      install, see below
- [x] Pull in NixOS/nixos-hardware's lenovo-thinkpad-x1-nano-gen1 module
      (flake input + import in hosts/x1nano/configuration.nix) - gives
      trackpoint config, the known x1-nano audio-interference fix, and TLP
      power management for free
- [x] Fingerprint reader: services.fprintd.enable = true (from the hardware
      module above) - still need to run `fprintd-enroll` after first boot
- [ ] Push nixos-config to a git remote (GitHub or similar) - currently has
      no remote configured at all (`git remote -v` is empty), and
      bootstrap.sh's REPO_URL is still the placeholder. Blocks the x1nano
      bootstrap's deploy-key clone step
- [ ] Finish migrating data off the Arch install
- [ ] Laptop hardware-configuration.nix - regenerate for real during the
      actual install (LUKS-encrypted root), see BOOTSTRAP.md's x1nano section
- [ ] Power management: TLP now on by default via nixos-hardware; backlight
      and any further battery tuning still open
- [ ] Sway desktop config, ported from current Arch setup
- [ ] Home Manager config shared between bubu-brain and laptop

## Claude Code guardrails (unrelated to nixos-config)
- [ ] Set up predictable guardrails for git usage etc (settings.json
      permissions/hooks) so it doesn't do unpredictable things
