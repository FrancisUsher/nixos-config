# Nix / flake-input upgrades

- [x] Bump nixpkgs from nixos-24.11 (just what the minimal installer
      happened to ship with, not a deliberate pin) to nixos-26.05 (current
      stable) - also bumped home-manager, nixvim, and stylix to their
      matching nixos-26.05/release-26.05 branches. Fixed the one breakage
      it surfaced: nixvim renamed `plugins.nvim-colorizer` to
      `plugins.colorizer` (modules/nixvim.nix). `nixos-rebuild build`
      confirmed clean for both bubu-brain and x1nano. Not yet switched on
      the live bubu-brain machine - `nixos-rebuild switch` + a real reboot
      is a separate, deliberate step, not something to do unattended.
      Unlocked:
      - [x] nixvim's plugins.lazydev module (added upstream after the
        nixos-24.11 branch was cut) - see modules/nixvim.nix's lazydev
        extraConfigLua wiring for what could then move to a real option
      - [x] Automatic Stylix theming for starship (its starship target
        doesn't exist on release-24.11, confirmed present on
        release-26.05) - see the "Automatic Stylix theming for starship"
        item in [[dotfiles-and-editor|Dotfiles and editor]]
      - Home-manager module for glow - checked release-26.05, still no
        `programs.glow` module (only bat.nix exists under modules/programs/
        for anything markdown/pager-adjacent). Not just a "hasn't landed
        yet" gap either - checked alternative terminal markdown renderers
        (mdcat, frogmouth) and none of them have a home-manager module
        either, so there's nothing to switch to. home.nix's glow config
        stays a plain xdg.configFile indefinitely; dropping this as
        something to keep re-checking on future bumps.
- [x] ~~Bump home-manager specifically to its master/unstable branch to pick
      up programs.claude-code~~ Turned out unnecessary - checked and
      `programs.claude-code` already exists on release-26.05 (module dir at
      modules/programs/claude-code/), so the 26.05 bump above gets it for
      free without needing to touch unstable at all. Actually wiring it up
      (settings.json/CLAUDE.md/hooks/agents/commands/skills/MCP-LSP
      servers) is a separate task - see
      [[claude-code-guardrails|Claude Code guardrails]].
