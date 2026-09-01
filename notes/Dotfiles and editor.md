# Dotfiles / editor

Depends on [[Home Manager]].

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
- [ ] Automatic Stylix theming for starship - blocked on [[Nix flake-input upgrades]]; until then starship uses its
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
      "Port sway config" / "Sway desktop config" in [[Migrate Arch laptop to NixOS]]
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
