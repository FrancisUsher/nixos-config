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
- [x] Port zsh config (.zshrc + .config/zsh) - zsh is now the actual login
      shell (programs.zsh.enable at the system level in both hosts'
      configuration.nix, users.users.soong.shell = pkgs.zsh), not just a
      side config; bash stays enabled in home.nix as a fallback. Ported:
      vi keybindings (defaultKeymap = "viins"), history size/save (20000/
      50000, matching the original numbers), the bb() mosh-to-bubu-brain
      function, and the ls/:q/vim/battery aliases (battery needed adding
      pkgs.acpi). NEWT_COLORS moved to home.sessionVariables verbatim -
      already Stylix-themed for free via modules/stylix.nix's
      stylix.targets.console.enable, since newt reads its named-color
      slots off the TTY's 16-color palette. autohack moved to
      modules/captive-portal.nix as environment.shellAliases (laptop-only,
      co-located with the rest of x1nano's wifi tooling) instead of living
      in home.nix. Dropped: the bare-repo `dots` alias (redundant now that
      this repo IS the dotfile source of truth), `todo.sh` (unused),
      `yay=paru` (Arch/AUR, no NixOS equivalent), the custom _git
      completion script (redundant - Nix's git package already ships zsh
      completions, picked up by programs.zsh.enableCompletion), and the
      oh-my-posh init (already superseded by starship). `icat` (kitten
      icat) deliberately deferred until kitty itself is ported - `kitten`
      doesn't exist yet. Atuin (for history) considered and deferred, see
      "Things to investigate" below.
- [x] Replace oh-my-posh with starship (no Stylix module exists for
      oh-my-posh). home.nix's programs.starship is enabled.
- [ ] Automatic Stylix theming for starship - blocked on the "Nix /
      flake-input upgrades" section above; until then starship uses its
      default prompt styling, untouched by Stylix.
- [x] Port fastfetch config - home.nix's programs.fastfetch, dropped the
      "editor" module (arch-reference's own config had it commented
      "TODO: this doesn't work") and the aspirational qutebrowser/launcher/
      clipboard-history wishlist comments (JSONC comments don't survive
      home-manager's JSON generator anyway, and those aren't real fastfetch
      module types). Logo/display.color now vary by hostName (flake.nix's
      mkHost passes it via home-manager.extraSpecialArgs) instead of the
      original's hardcoded "arch3" - a first step toward per-host theming,
      not the full home.nix split. x1nano/red-sun-whorl has no real base16
      theme yet (see project-x1nano-red-sun-whorl memory), so it just gets
      a different named accent color for now, not real palette-driven
      theming like bubu-brain's Ancient Ruins
- [x] Port gh config - home.nix's programs.gh (settings.aliases.co = "pr checkout",
      matching arch-reference's config.yml). Deliberately does NOT touch
      hosts.yml - that file holds a live oauth_token in plaintext, auth stays
      a manual `gh auth login` step (see "GitHub CLI" section below).
      programs.gh's default gitCredentialHelper also reproduces the
      credential.helper stanza from .gitconfig for free
- [x] ~~Port gitui config~~ Dropped - not something actually in use, and
      there was no config to port anyway (arch-reference's gitui config
      dir was empty). Not installed.
- [x] Port go config - no real dotfiles existed to port (arch-reference's
      go config dir was just telemetry cache, not settings), so this is
      just installing `go` via environment.systemPackages on both hosts
      (system-wide, not per-user home.nix)
- [x] Port uv config - same story as go above: arch-reference's uv config
      dir was just an installer receipt, nothing to port. `uv` added to
      environment.systemPackages on both hosts
- [ ] Port kicad config
- [x] Port zmk (keyboard firmware) config - home.nix's xdg.configFile for
      zmk.ini, pointing `home` at $HOME/dev/zmk-config via
      config.home.homeDirectory rather than hardcoding a username (the
      original arch-reference file hardcoded /home/silk, which happens to
      already be the account name on the real laptop - see
      project-x1nano-red-sun-whorl notes). No package added: the zmk build
      toolchain (west) isn't packaged here, this is just the config file
      it reads
- [x] Port glow config - no home-manager module for glow on this pin, so
      it's home.packages + xdg.configFile."glow/glow.yml" in home.nix,
      copied verbatim from arch-reference (no personal data/secrets in it)
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
- [x] git config - home.nix's programs.git (userName/userEmail/init.defaultBranch/
      core.editor). Credential helper isn't set here; it comes from
      programs.gh's gitCredentialHelper (see "Port gh config" above) instead
      of being duplicated by hand
- [ ] Other QoL tools worth considering: direnv

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

## Things to investigate (low priority, no immediate need)
- [ ] Investigate quickshell as a possible replacement for the waybar/
      swaylock/mako stack. QML-based, single persistent process instead of
      several small ones - more flexible than waybar's JSON+CSS but likely
      higher idle RAM (Qt/QML runtime); unmeasured, so benchmark before
      actually switching rather than assuming.
- [ ] Investigate atuin for shell history, instead of/alongside plain zsh
      history. Its one differentiator over what's already planned (fzf's
      Ctrl+R fuzzy search, already covered) is cross-host history sync
      between bubu-brain and red-sun-whorl - worth it only if that's
      actually wanted day to day. Costs: contests Ctrl+R with fzf's zsh
      integration (fixable, but a real conflict to resolve), moves history
      into a SQLite db it owns instead of a plain HISTFILE, and needs
      either trusting atuin's hosted sync or running your own sync server.
      No need to decide now - zsh port (below) uses plain zsh history
      until/unless this gets picked up.
