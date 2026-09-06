# Dotfiles migration gaps

Loose ends found while triaging `arch-reference/` for deletion. See
[[dotfiles-and-editor|Dotfiles and editor]] for what was ported where.

- [ ] Real Sway wallpaper never ported. `arch-reference/.config/sway/
      wallpaper.jpg` still exists on disk (kept, not deleted) but
      modules/stylix.nix's `stylix.image` is currently a generated 1x1
      placeholder in the palette's background color, with a comment saying
      to swap it once a real Sway session exists - which it now does. Also
      noted as an open idea ("a themed wallpaper now that Sway exists") in
      the pruned refile.md per
      [[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]]. Todo:
      decide whether to reuse this exact wallpaper.jpg or pick something
      new for the Solar Cycle theme, then copy it into the tracked repo
      (arch-reference is gitignored, same treatment as the oreb Plymouth
      assets got) and point stylix.image at it.
- [ ] `.config/yazi/yazi.toml` has one real (non-default) setting,
      `show_hidden = true`, that was never ported - only the yazi package
      itself got enabled (modules/programs/cli-tools.nix). File kept in
      arch-reference for now. Todo: add `settings.mgr.show_hidden = true`
      to programs.yazi's settings once yazi config gets another pass.
- [ ] Hyprland - deliberately set aside for now (arch-reference's
      hyprland.conf was untouched stock example config, nothing
      customized; Sway is what's actually in use), but expected to come
      back later as the real theming engine for the Solar Cycle look
      (animations, dynamic borders, transparency) once the migration
      itself is done - see
      [[red-sun-whorl-rename-plan|red-sun-whorl rename plan]].
