# Dotfiles / editor

- [x] Triage arch-reference/, prune junk before deciding what's worth converting
- [ ] Port sway config
- [ ] Port swaylock config
- [x] Port waybar config - home.nix's programs.waybar (settings.mainBar for
      config.jsonc, style for style.css), structured Nix options rather than
      an xdg.configFile text-dump. Kept modules-left (sway/workspaces,
      sway/mode, sway/scratchpad), modules-center (sway/window), and
      modules-right (network, battery, clock, tray) with their formats/
      icons/click-behavior as configured. Dropped: keyboard-state, mpd,
      idle_inhibitor, cpu, memory, temperature, backlight, battery#bat2,
      power-profiles-daemon, and pulseaudio - all configured in the
      original but never actually wired into modules-left/center/right
      (commented out of the arrays or just never added), so dead config
      blocks. Also dropped custom/media and custom/power even though both
      were active in modules-left/right - their backing scripts
      (mediaplayer.py, power_menu.xml) don't exist anywhere in
      arch-reference; the "// Script in resources folder" / "// Menu file
      in resources folder" comments are straight from Waybar's stock
      upstream example config, never actually replaced with real scripts.
      style.css stripped of every hardcoded color (hex, rgba, and the old
      @color-* GTK defines from palette.css) per Stylix now owning waybar
      theming (stylix.targets.waybar.enable, already dormant-but-set in
      home.nix) - kept `transparent` since it's an absence of color, not a
      themed value. Rules that were 100% about color (workspace
      focused/urgent backgrounds, hover backgrounds, the battery-critical
      blink @keyframes - a blink is meaningless once the two colors it
      alternates between are stripped) dropped entirely rather than left
      as empty rulesets. Also dropped a hardcoded `* { font-family:
      FontAwesome, MesloLGM Nerd Font Mono, ... }` rule - fonts are a
      Stylix concern too (stylix.fonts), and since home-manager
      concatenates programs.waybar.style after the stylix waybar target's
      own output, that rule was silently overriding Stylix's actual
      (verified-installed) font choice with a hardcoded one that may not
      even exist on NixOS. Verified both `nixos-rebuild build` for x1nano
      and bubu-brain, and inspected the built waybar-config.json/style.css
      in the Nix store to confirm Stylix's base16 colors and font land
      correctly on top of the structural CSS.
- [ ] Port fuzzel config
- [ ] Port kitty config
- [x] Port zsh config (.zshrc + .config/zsh) - zsh is now the actual login
      shell (programs.zsh.enable at the system level in both hosts'
      configuration.nix, users.users.soong.shell = pkgs.zsh), not just a
      side config; bash stays enabled in home.nix as a fallback. Ported:
      vi keybindings (defaultKeymap = "viins"), history size/save (20000/
      50000, matching the original numbers), the bb() mosh-to-bubu-brain
      function, and the ls/:q/vim/battery aliases (battery needed adding
      pkgs.acpi). NEWT_COLORS moved to modules/stylix.nix's
      environment.sessionVariables (a theming concern, not a personal
      shell setting - it belongs with the rest of the theming glue, next
      to tuigreet-theme.nix, and needs to be system-wide since it's read
      by nmtui/whiptail sessions including root's, not just soong's
      home-manager session) - already Stylix-themed for free via
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
      [[things-to-investigate|Things to investigate]].
- [x] Replace oh-my-posh with starship (no Stylix module exists for
      oh-my-posh). home.nix's programs.starship is enabled.
- [ ] Wire up Stylix theming for starship - no longer blocked, the
      [[nix-flake-input-upgrades|Nix flake-input upgrades]] bump to
      release-26.05 confirmed the starship target exists there
      (stylix.targets.starship.enable or equivalent, alongside the other
      per-app targets in home.nix's stylix.targets block). Right now
      starship runs on its pure upstream defaults (no `settings` block at
      all in home.nix's programs.starship) - which is also why the prompt
      visibly shifted after the 26.05 bump, since starship itself moved
      1.22.1 -> 1.25.1 and its zero-config default changed underneath us.
- [ ] Design a real themed starship prompt matching bubu-brain's Ancient
      Ruins palette (modules/themes/ancient-ruins.nix) - not just flipping
      on the auto Stylix target above, but actually choosing a format/module
      set/icons that feels like Ancient Ruins rather than generic
      base16-recolored defaults.
- [x] Port fastfetch config - home.nix's programs.fastfetch, dropped the
      "editor" module (arch-reference's own config had it commented
      "TODO: this doesn't work") and the aspirational qutebrowser/launcher/
      clipboard-history wishlist comments (JSONC comments don't survive
      home-manager's JSON generator anyway, and those aren't real fastfetch
      module types). Logo/display.color now vary by hostName (flake.nix's
      mkHost passes it via home-manager.extraSpecialArgs) instead of the
      original's hardcoded "arch3" - a first step toward per-host theming,
      not the full home.nix split. x1nano/red-sun-whorl has no real base16
      theme yet (see [[red-sun-whorl-rename-plan|red-sun-whorl rename plan]]),
      so it just gets a different named accent color for now, not real
      palette-driven theming like bubu-brain's Ancient Ruins
- [x] Port gh config - home.nix's programs.gh (settings.aliases.co = "pr checkout",
      matching arch-reference's config.yml). Deliberately does NOT touch
      hosts.yml - that file holds a live oauth_token in plaintext, auth stays
      a manual `gh auth login` step. programs.gh's default gitCredentialHelper also reproduces the
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
      [[red-sun-whorl-rename-plan|red-sun-whorl rename plan]]). No package
      added: the zmk build toolchain (west) isn't packaged here, this is
      just the config file it reads
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
      "Port sway config" / "Sway desktop config" in
      [[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]]
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
      programs.gh's gitCredentialHelper (see the gh item above) instead
      of being duplicated by hand
- [ ] Other QoL tools worth considering: direnv
- [ ] Consider splitting home.nix into modules/programs/*.nix per app -
      it's picked up a lot of weight from these ports (waybar's block alone
      is ~140 lines including the style.css heredoc) and is starting to
      feel like it wants the same per-concern module split as modules/*.nix
      already gets for system-level config. Worth doing once the current
      round of parallel arch-reference ports (waybar/kitty/fuzzel/sway/etc.)
      has landed, not mid-flight - splitting now would conflict with every
      one of those in-progress edits.
