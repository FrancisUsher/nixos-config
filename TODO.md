# TODO

## Nix release bump
- [ ] Bump nixpkgs from nixos-24.11 (just what the minimal installer
      happened to ship with, not a deliberate pin) to nixos-26.05 (current
      stable) - also bump home-manager, nixvim, and stylix to their matching
      nixos-26.05 branches, then rebuild and verify bubu-brain boots and
      works before trusting it. Do as its own isolated task, not bundled
      with unrelated concurrent changes, so a regression is attributable.
      Picks up nixvim's plugins.lazydev module for free (added upstream
      after the nixos-24.11 branch was cut) - see modules/nixvim.nix's
      lazydev extraConfigLua wiring for what could then move to a real
      option.

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
- [ ] Port zsh config (.zshrc + .config/zsh) - independent of starship/prompt
      theming below; starship is wired to bash via
      programs.starship.enableBashIntegration, so zsh isn't a prerequisite
- [x] Replace oh-my-posh with starship (no Stylix module exists for
      oh-my-posh). home.nix's programs.starship is enabled.
- [ ] Automatic Stylix theming for starship - needs stylix >= release-25.05
      (its starship target doesn't exist on release-24.11, which is what
      we're pinned to). Revisit with the "Nix release bump" item above;
      until then starship uses its default prompt styling, untouched by
      Stylix.
- [ ] Port fastfetch config
- [ ] Port gh config
- [ ] Port gitui config
- [ ] Port go config
- [ ] Port uv config
- [ ] Port kicad config
- [ ] Port zmk (keyboard firmware) config
- [ ] Port glow config
- [ ] Port qutebrowser config
- [x] ~~Reproduce custom theming scripts~~ Superseded by adopting Stylix
      (nix-community/stylix) instead of porting the Python/Jinja engine - see
      modules/stylix.nix and modules/themes/ancient-ruins.nix (the "Ancient
      Ruins" palette ported to base16). arch-reference/themer/ is kept, not
      deleted, since plymouth_themes/oreb/ is still needed below.
- [ ] Port oreb Plymouth theme (arch-reference/themer/plymouth_themes/oreb/ -
      owl.script + animation frames) to consume config.lib.stylix.colors,
      replacing Stylix's built-in Plymouth theme/logo currently in use
- [ ] Full greetd + tuigreet bring-up (services.greetd.enable, session
      launch command) wired to modules/tuigreet-theme.nix's
      config.lib.tuigreet.themeArg. Gated on Sway session existing - see
      "Port sway config" / "Sway desktop config" below
- [ ] Once the oreb Plymouth port (if it happens) is complete, prune
      arch-reference/themer/'s Python engine (main.py, input/, output/,
      .venv/, uv.lock, pyproject.toml) as dead code
- [ ] Review system-config/collect.zsh - old Arch dotfiles-workflow experiment,
      list of /etc files it tracked may be useful as a checklist
- [x] ~~Import orgfiles/ into a nvim-orgmode setup~~ Superseded by
      plugins.obsidian (modules/nixvim.nix) instead of nvim-orgmode -
      orgfiles/refile.org's actual content still needs converting from org
      syntax to markdown and dropping into the ~/notes vault, see below
- [ ] Migrate orgfiles/refile.org's content (org syntax) to markdown in the
      ~/notes Obsidian vault - deferred out of the orgmode->obsidian swap
- [ ] Install neovim via Home Manager
- [ ] Migrate nvim config from Arch laptop
- [ ] Custom flake check process for catching a broken plugin/nixpkgs update
      (e.g. nvim failing to start) before committing the flake.lock bump,
      instead of discovering it several revisions later - needs its own
      longer discussion about what would actually meet my needs here
- [ ] tmux keybind remap (closer to Sway's mental model)
- [ ] git config
- [ ] Other QoL tools worth considering: direnv, atuin

## bubu-brain hardware
- [ ] Verify acpi_enforce_resources=lax (hosts/bubu-brain/rgb.nix) actually
      fixes RAM RGB staying off after a real cold power off/on - added
      after RAM lit back up post power cycle, only tested via warm reboot
      so far. [Note - I did a cold restart and it was not fixed. Need to
      troubleshoot this a bit more]

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
- [ ] Laptop hardware-configuration.nix's fileSystems/swapDevices/
      boot.initrd.luks are hand-filled placeholders matching BOOTSTRAP.md's
      documented partition plan (by-label/by-partlabel refs), not from a
      real scan - just enough for `nix flake check`/`nixos-rebuild build` to
      pass instead of failing the fileSystems assertion. MUST be regenerated
      for real during the actual install (nixos-generate-config --root /mnt,
      per BOOTSTRAP.md's x1nano section) - don't trust these values to boot
      the real hardware as-is
- [ ] Power management: TLP now on by default via nixos-hardware; backlight
      and any further battery tuning still open
- [ ] Sway desktop config, ported from current Arch setup
- [ ] Home Manager config shared between bubu-brain and laptop

## Claude Code guardrails (unrelated to nixos-config)
- [ ] Set up predictable guardrails for git usage etc (settings.json
      permissions/hooks) so it doesn't do unpredictable things
