# Nix / flake-input upgrades

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
        theming for starship" item in [[dotfiles-and-editor|Dotfiles and editor]]
      - Possibly a home-manager module for glow - none exists on this
        release-24.11 pin, so home.nix's glow config is a plain
        xdg.configFile instead of a programs.glow block; switch it over
        if one lands
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
