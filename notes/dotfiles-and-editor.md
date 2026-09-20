# Dotfiles / editor

Most of the Arch dotfiles migration is done. Ported into home.nix /
modules/programs/*.nix, each pulling colors from Stylix's Ancient Ruins
base16 palette instead of hardcoded hex: sway, swaylock, waybar, fuzzel,
kitty, zsh (login shell, vi keybindings, the `bb()` mosh-to-bubu-brain
function, ls/battery aliases), starship (replacing oh-my-posh, themed via
Stylix, reusing the old oh-my-posh layout), fastfetch, gh, go, uv, kicad,
zmk, glow, and qutebrowser. The oreb Plymouth theme
(arch-reference/themer/plymouth_themes/oreb/) is packaged as
modules/plymouth-oreb.nix, with two real bugs fixed in the port (wrong
script filename, FHS-only paths) and its text color wired to
`config.lib.stylix.colors`; `boot.plymouth.enable` itself is still off,
left as a separate decision. greetd + tuigreet is fully wired on
red-sun-whorl (modules/greetd-sway.nix). nvim migrated to nixvim
(modules/nixvim.nix), matching the old kickstart.nvim LSP/treesitter/plugin
set. tmux got a Sway-style keybind table (remote-operations.nix), and
home.nix was split into one file per program under modules/programs/*.nix
(verified byte-identical against the pre-split generated output). Dropped
rather than ported: gitui (unused, empty config), the old Python/Jinja
theming engine (superseded by Stylix), and the Arch-specific /etc-file sync
in system-config/collect.zsh (superseded by NixOS's declarative config).
orgfiles/refile.org's still-relevant ideas were migrated to ~/notes/refile.md
(outside this repo's scope).

- [ ] Starship prompt is missing the original's segment-separator glyphs -
      arch-reference's oh-my-posh theme used two Nerd Font "Powerline Extra
      Symbols" glyphs (U+E0CA leading, U+E0C6 trailing - blocky/pixelated
      diamonds, not plain arrows) as delimiters between segments; the
      starship port carries over colors/layout but dropped these, so
      segments currently butt up against each other. Revisit once
      starship's format/style strings are being tuned again - it supports
      arbitrary glyphs in each module's format string.
- [ ] Zsh config is functional but was never actually designed - francis
      accidentally deleted the in-progress config partway through the
      original port and redid it quickly out of frustration rather than
      going through the intended setup carefully. Todo: sit down together
      and go through zsh config deliberately (aliases, prompt integration,
      plugins/completions worth having, etc.) rather than treating the
      current config as final.
- [ ] Prune arch-reference/themer/'s Python engine (main.py, input/,
      output/, .venv/, uv.lock, pyproject.toml) as dead code, now that the
      oreb Plymouth port is complete - deliberately left alone since it's a
      destructive delete of local files outside git (arch-reference/ is
      gitignored); do it whenever it's actually wanted.
- [ ] Custom flake check process for catching a broken plugin/nixpkgs
      update (e.g. nvim failing to start) before committing the flake.lock
      bump, instead of discovering it several revisions later - needs its
      own longer discussion about what would actually meet my needs here.
- [ ] Other QoL tools worth considering: direnv
