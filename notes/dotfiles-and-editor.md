# Dotfiles / editor

- [x] Triage arch-reference/, prune junk before deciding what's worth converting
- [x] Port sway config - home.nix's wayland.windowManager.sway, using
      structured options (modifier/terminal/menu/window/floating/gaps/bars/
      keybindings) instead of extraConfig. Most keybindings needed no
      override - arch-reference was close to stock sway defaults already.
      Colors dropped (Stylix themes sway now). Also dropped:
      frame_orchestrator.py (unused WIP script), the Arch-only `include
      /etc/sway/config.d/*`, and cliphist (its retrieval script,
      ~/.local/bin/fuzzel-cliphist, was never captured into
      arch-reference). bars uses `command = "waybar"`. Both hosts build
      clean, including sway --validate on the generated config.
- [x] Port swaylock config - home.nix's programs.swaylock, ported only the
      non-color behavioral setting (ignore-empty-password); arch-reference's
      font=Ubuntu was dropped too since no Ubuntu font package is installed
      on either host (Stylix only sets a monospace role via
      stylix.fonts.monospace) - it would've just silently fallen back to a
      default anyway, not an intentional choice worth hardcoding. All of
      arch-reference's hardcoded hex colors (color/ring-*/inside-*/line-*/
      text-*/bs-hl-color/caps-lock-*-hl-color) were dropped rather than
      copied - stylix.targets.swaylock turned out to already exist on this
      pin (release-26.05, confirmed by reading nix-community/stylix's
      modules/swaylock/hm.nix out of the flake input's store path) and is
      now enabled in home.nix's stylix.targets block alongside the other
      per-app targets, so swaylock gets the Ancient Ruins palette for free
      (base01 background/inside, base05 ring/text, base0B key-hl,
      base08 wrong, plus stylix.image for the lock background) instead of
      arch-reference's old themer/-driven hex values. No indicator/grace-
      period/effects settings existed in the original config to port.
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
      even exist on NixOS. Verified both `nixos-rebuild build` for red-sun-whorl
      and bubu-brain, and inspected the built waybar-config.json/style.css
      in the Nix store to confirm Stylix's base16 colors and font land
      correctly on top of the structural CSS.
- [x] Port fuzzel config - home.nix's programs.fuzzel, settings as a
      structured attrset (not xdg.configFile text) mirroring fuzzel.ini's
      [section]/key layout. arch-reference's fuzzel.ini had almost
      everything commented out (pure defaults) except [main]
      filter-desktop=yes, which is what's ported (filter-desktop = true).
      The whole [colors] section, and fuzzel.ini's `include=theme.ini` (the
      old Python/Jinja engine's per-app override file), are dropped -
      that's Stylix's job now via stylix.targets.fuzzel.enable (already
      wired in home.nix, was sitting dormant waiting on this port); Stylix
      injects the Ancient Ruins palette plus font/icon-theme itself, so
      those aren't set here to avoid clashing. The one non-color value
      inside theme.ini's [border] section (width=4, radius=0, vs fuzzel's
      own default of width=3) is a genuine layout override rather than
      theming, so that's carried over too
- [x] Port kitty config - home.nix's programs.kitty, with structured settings
      (scrollback_lines, mouse_hide_wait, hide_window_decorations,
      tab_bar_style/tab_powerline_style = powerline/round,
      allow_remote_control) plus shellIntegration.enable{Bash,Zsh}Integration
      instead of relying on kitty's own auto-detected integration. No map
      lines ported - every keybinding in arch-reference's kitty.conf was
      commented out, so there was nothing active to carry over. Colors,
      cursor/selection styling, and the `include current-theme.conf` /
      themer/input/kitty Jinja leftovers were all dropped per
      stylix.targets.kitty.enable (already dormant in home.nix, now live) -
      Stylix injects the Ancient Ruins palette instead. Also dropped the
      hardcoded font_family (`MesloLGM Nerd Font Mono`, the M/medium-width
      Meslo variant) since it's a different variant of the same font
      stylix.fonts.monospace already manages (`MesloLGS Nerd Font Mono`,
      S/small-width) - not a deliberate distinct font choice, so left to
      Stylix rather than fighting it. En route, fixed a pre-existing
      `pkgs.nerdfonts` -> `pkgs.nerd-fonts.meslo-lg` breakage in
      modules/stylix.nix (nixpkgs renamed/restructured the nerd-fonts
      package set; this was latent because nothing had evaluated
      stylix.fonts.monospace.package until an app under a stylix target
      actually got enabled)
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
      co-located with the rest of red-sun-whorl's wifi tooling) instead of living
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
- [x] Wire up Stylix theming for starship + design a real themed prompt -
      starship split out of cli-tools.nix into its own modules/programs/
      starship.nix (it now has real content, no longer just a one-line
      enable), stylix.targets.starship.enable turns on the base16 palette
      injection (palette = "base16" + palettes.base16 with all the named
      slots), and programs.starship.settings defines a diamond/powerline
      format that deliberately reuses arch-reference's retired oh-my-posh
      layout (.config/oh-my-posh/colored.omp.toml) instead of inventing a
      new design from scratch: username segment on red, directory on green,
      git branch/status on cyan, time on purple, dark (base00/"black") text
      on every segment - same four segments, same color-to-segment mapping,
      just re-expressed as Starship module configs against Stylix's base16
      palette names instead of hardcoded hex. Verified the rendered
      starship.toml in the Nix store resolves those palette names to the
      exact Ancient Ruins hex values.
- [x] Port fastfetch config - home.nix's programs.fastfetch, dropped the
      "editor" module (arch-reference's own config had it commented
      "TODO: this doesn't work") and the aspirational qutebrowser/launcher/
      clipboard-history wishlist comments (JSONC comments don't survive
      home-manager's JSON generator anyway, and those aren't real fastfetch
      module types). Logo/display.color now vary by hostName (flake.nix's
      mkHost passes it via home-manager.extraSpecialArgs) instead of the
      original's hardcoded "arch3" - a first step toward per-host theming,
      not the full home.nix split. red-sun-whorl has no real base16
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
- [x] Port kicad config - no home-manager module for kicad exists on this
      pin, and arch-reference's kicad config dir had nothing worth porting
      anyway: colors/ was empty (no custom color theme ever saved) and
      kicad_common.json was pure app state (recent-file paths, window
      geometry, blank git author, default backup settings) rather than
      anything intentional. So this is just `kicad` added to
      environment.systemPackages on both hosts, same treatment as go/uv
      above.
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
- [x] Port qutebrowser config - home.nix's programs.qutebrowser
      (modules/programs/qutebrowser.nix), settings as a structured attrset
      (auto_save.session, colors.webpage.darkmode.enabled, content.images)
      instead of xdg.configFile text. The per-domain image whitelist loop
      from arch-reference's config.py (`whitelist_images()` over a list of
      11 URL patterns) maps directly onto the module's perDomainSettings
      option - one entry per pattern instead of a Python loop. Dropped
      `config.load_autoconfig(False)` since it's already the module's
      default (loadAutoconfig = false). No colors/keybindings/aliases
      existed in the original to port - config.py was 34 lines, entirely
      the settings above. Verified the generated config.py in the Nix store
      matches arch-reference's config.set() calls byte-for-byte in meaning.
- [x] ~~Reproduce custom theming scripts~~ Superseded by adopting Stylix
      (nix-community/stylix) instead of porting the Python/Jinja engine - see
      modules/stylix.nix and modules/themes/ancient-ruins.nix (the "Ancient
      Ruins" palette ported to base16). arch-reference/themer/ is kept, not
      deleted, since plymouth_themes/oreb/ is still needed below.
- [x] Port oreb Plymouth theme (arch-reference/themer/plymouth_themes/oreb/ -
      owl.script + animation frames) to consume config.lib.stylix.colors,
      replacing Stylix's built-in Plymouth theme/logo currently in use -
      packaged as modules/plymouth-oreb.nix + modules/plymouth-oreb/theme/
      (the 151 progress-N.png frames, LICENSE, and script/theme files copied
      out of the gitignored arch-reference/ into the tracked repo, since a
      flake can't reference gitignored paths). This theme is a vendored
      third-party one (adi1090x's, GPLv3, LICENSE carried along) renamed
      "oreb" - not yet the custom bird/whorl animation from refile.org's
      TODO, which is a separate future undertaking. Two real bugs fixed in
      the port, not just recolored: (1) owl.plymouth's ScriptFile pointed at
      "oreb.script" but the shipped file was named "owl.script" - this
      theme could never have actually loaded on the old Arch box either;
      (2) ImageDir/ScriptFile hardcoded /usr/share/plymouth/themes/oreb,
      an FHS path that doesn't exist on NixOS - repointed at
      /etc/plymouth/themes/oreb, which is where NixOS's boot.plymouth
      module actually exposes theme packages (both in the real root and,
      separately, inside the initrd - confirmed by reading nixpkgs'
      nixos/modules/system/boot/plymouth.nix). The 5 hardcoded
      `Image.Text(..., 1, 1, 1)` (white) calls become
      `config.lib.stylix.colors.base05-dec-{r,g,b}` via pkgs.replaceVars
      against a .tmpl file, so password/message text now tracks whatever
      base16 scheme is active instead of being frozen to white. Verified
      by building `boot.plymouth.themePackages` directly and reading the
      generated oreb.script out of the store (colors substituted correctly)
      alongside the usual `nixos-rebuild build` for both hosts.
      stylix.targets.plymouth.enable is now off in modules/stylix.nix in
      favor of this theme. Deliberately NOT flipping boot.plymouth.enable
      itself (still false, as it was before this) - actually turning the
      boot splash on is a separate decision with real on-device boot
      behavior, left for later. Now unblocks the next item below.
- [ ] Full greetd + tuigreet bring-up (services.greetd.enable, session
      launch command) wired to modules/tuigreet-theme.nix's
      config.lib.tuigreet.themeArg. Gated on Sway session existing - see
      "Port sway config" / "Sway desktop config" in
      [[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]]
- [ ] Now that the oreb Plymouth port is complete (above), prune
      arch-reference/themer/'s Python engine (main.py, input/, output/,
      .venv/, uv.lock, pyproject.toml) as dead code - deliberately left
      alone for now since it's a destructive delete of local files outside
      git (arch-reference/ is gitignored) that wasn't explicitly asked for
      this session; do it whenever it's actually wanted.
- [x] Review system-config/collect.zsh - old Arch dotfiles-workflow experiment,
      list of /etc files it tracked may be useful as a checklist. Reviewed:
      it synced /etc/mkinitcpio.conf, /etc/pacman.conf, /etc/vconsole.conf,
      /etc/locale.gen, and /etc/mkinitcpio.d/linux.preset into a git-tracked
      copy by hand (sudo cp + chown). All five are Arch-specific concepts
      NixOS already declares natively and rebuilds from source instead of
      hand-syncing: pacman.conf has no NixOS equivalent (nix.settings /
      environment.systemPackages replace it entirely), mkinitcpio.conf/
      linux.preset are superseded by boot.initrd's declarative config,
      vconsole.conf/locale.gen are superseded by console.* and i18n.*
      options (already set in both hosts' configuration.nix). Nothing to
      port; the checklist purpose is satisfied by configuration.nix itself.
- [x] ~~Import orgfiles/ into a nvim-orgmode setup~~ Superseded by
      plugins.obsidian (modules/nixvim.nix) instead of nvim-orgmode -
      orgfiles/refile.org's actual content still needs converting from org
      syntax to markdown and dropping into the ~/notes vault, see below
- [ ] Migrate orgfiles/refile.org's content (org syntax) to markdown in the
      ~/notes Obsidian vault - deferred out of the orgmode->obsidian swap
- [x] ~~Install neovim via Home Manager~~ / ~~Migrate nvim config from Arch
      laptop~~ Already done, checklist just hadn't caught up: modules/
      nixvim.nix fully ports arch-reference's kickstart.nvim-based config
      (.config/nvim/lua/kickstart + lua/custom) via nix-community/nixvim
      instead of lazy.nvim - same LSP servers (lua_ls, basedpyright, cssls,
      taplo, ts_ls), same treesitter grammar set, same telescope/blink-cmp/
      conform/gitsigns/which-key/obsidian plugin list and keymaps, colors
      from stylix.targets.nixvim instead of a hardcoded colorscheme.
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
- [x] Split home.nix into modules/programs/*.nix per app - one file per
      program (git/gh/glow/fastfetch/zmk/zsh/kitty/sway/swaylock/waybar/
      fuzzel), plus modules/programs/cli-tools.nix for the one-line enables
      (bash/bat/ripgrep/fzf/starship/zoxide/yazi) that didn't warrant their
      own file. Each app's stylix.targets.<app>.enable line moved into that
      app's own module (including nixvim's, now in modules/nixvim.nix)
      instead of staying centralized, so a module owns its own theming
      enablement. home.nix is now just the entrypoint: imports list, user
      identity (username/homeDirectory/stateVersion), and the couple of
      genuinely cross-cutting home.shellAliases/home.sessionVariables that
      don't belong to any one app. Verified behavior-preserving, not just
      "builds clean": diffed the full generated home-manager-files tree
      between master and this split - byte-identical except unavoidable
      embedded store-path self-references and one shell function landing in
      a harmless different position in .zshrc (import order changed, content
      didn't).
