# TODO

## Nix / flake-input upgrades
- [ ] Bump nixpkgs from nixos-24.11 (just what the minimal installer
      happened to ship with, not a deliberate pin) to nixos-26.05 (current
      stable) - also bump home-manager, nixvim, and stylix to their matching
      nixos-26.05 branches, then rebuild and verify bubu-brain boots and
      works before trusting it. Do as its own isolated task, not bundled
      with unrelated concurrent changes, so a regression is attributable.
      Unlocks:
      - nixvim's plugins.lazydev module (added upstream after the
        nixos-24.11 branch was cut) - see modules/nixvim.nix's lazydev
        extraConfigLua wiring for what could then move to a real option
      - Automatic Stylix theming for starship (its starship target
        doesn't exist on release-24.11) - see the "Automatic Stylix
        theming for starship" item in Dotfiles/editor
- [ ] Bump home-manager specifically to its master/unstable branch to pick
      up programs.claude-code (doesn't exist on release-24.11, and isn't
      guaranteed to land on release-26.05 either - it's a newer module,
      check when the above bump happens). Manages the *global* ~/.claude/
      tree - settings.json, CLAUDE.md (via a context option), hooks,
      agents, commands, skills, MCP/LSP servers - declaratively. Distinct
      from the project-scoped CLAUDE.md/.claude/settings.json already
      committed in this repo, which need no home-manager involvement.
      Going to unstable is a deliberate version-pinning decision (see the
      release-lockstep comment in flake.nix), not a side effect of
      wanting this one module - decide whether to wait for a release
      branch or accept unstable sooner.

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
- [ ] Automatic Stylix theming for starship - blocked on the "Nix /
      flake-input upgrades" section above; until then starship uses its
      default prompt styling, untouched by Stylix.
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
- [x] tmux keybind remap (closer to Sway's mental model) - remote-operations.nix's
      programs.tmux, a dedicated "sway" key-table (Ctrl-Space prefix,
      h/j/k/l pane nav + resize, 1-0 window switching, split/zoom/kill/new-window)
- [ ] git config
- [ ] Other QoL tools worth considering: direnv, atuin

## bubu-brain hardware
- [x] Root-caused RAM RGB staying on after a cold power off/on: not the
      acpi_enforce_resources=lax kernel param (never actually the issue -
      dmesg never logged an ACPI resource conflict). The RAM's SMBus RGB
      chips (ENE, 0x70/0x71) have no kernel/udev readiness signal and can
      take a few seconds to start answering reads after a real cold boot;
      openrgb-off.service was only trying once, right after openrgb.service
      started, so a slow wake meant the whole off-profile silently failed
      to apply (openrgb's CLI exits 0 whether or not it succeeds) and every
      device - RAM and AIO both - was left at its power-on lighting
      default. Fixed in hosts/bubu-brain/rgb.nix: openrgb-off's ExecStart is
      now a small wrapper that retries up to 5 times, 2s apart, and only
      exits nonzero (a real failed unit) if none of the attempts report
      "Profile loaded successfully". Deployed and manually verified
      working; still wants confirmation across a few more real cold
      power-on cycles since that's the actual race being fixed.

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
- [x] Push nixos-config to a git remote - github.com/FrancisUsher/nixos-config
      (private). bootstrap.sh's REPO_URL now points at it (plain https, no
      auth wired up yet - it'll fail non-interactively against a private
      repo until the deploy-key question above is actually resolved)
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
- [x] Home Manager config shared between bubu-brain and laptop - flake.nix's
      mkHost wires home-manager.users.soong = import ./home.nix identically
      for both hosts
- [ ] Split home.nix into shared + per-host pieces - the laptop isn't just
      a themed variant of bubu-brain's user experience, it's a different
      structure entirely: hostname "red-sun-whorl" (Gene Wolfe's Solar
      Cycle), with two separate users instead of bubu-brain's single
      "soong" - "silk" (general-purpose, full Sway GUI) and "horn" (boots
      straight into a distraction-free writing tool, nothing else).
      home-manager.users.soong = import ./home.nix in flake.nix's mkHost
      won't work as-is once there's more than one user per host

## Repo visibility
- [ ] Add automated secret scanning to the repo (e.g. gitleaks/trufflehog as
      a pre-commit hook and/or CI check) - do this before making the repo
      public, not after, to catch accidental disclosures going forward
- [ ] Make github.com/FrancisUsher/nixos-config public - gated on the
      secret-scanning item above landing first

## Claude Code guardrails (unrelated to nixos-config)
- [ ] Set up predictable guardrails for git usage etc (settings.json
      permissions/hooks) so it doesn't do unpredictable things

## Desktop shell exploration (low priority, after initial dotfile porting)
- [ ] Investigate quickshell as a possible replacement for the waybar/
      swaylock/mako stack. QML-based, single persistent process instead of
      several small ones - more flexible than waybar's JSON+CSS but likely
      higher idle RAM (Qt/QML runtime); unmeasured, so benchmark before
      actually switching rather than assuming.
