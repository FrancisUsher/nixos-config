# red-sun-whorl rename plan

Referenced from [[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]].

The laptop is hosts/red-sun-whorl/, restructured beyond just a re-theme:

- [x] Hostname is **red-sun-whorl**, after Gene Wolfe's Solar Cycle novels.
- [x] The single migrated user account is **silk** (bubu-brain's user stays
      "soong" - flake.nix's `mkHost` takes a per-host username, wired as
      `home-manager.users.${username}`, and home.nix reads that username
      rather than hardcoding one).
- [ ] Still open: splitting off a second **horn** account - a dedicated
      distraction-free writing space that boots straight into a writing
      tool and does essentially nothing else. silk stays the
      general-purpose account, full GUI, Sway desktop (the "port sway
      config" etc. items in [[dotfiles-and-editor|Dotfiles and editor]] are
      for this user).

Why: the approach to this repo treats each host as a distinct
narrative/thematic experience, not just a functionally-tweaked variant.

How to apply: adding horn will need home.nix split further into a shared
base plus per-user configs (silk vs horn, not just a parameterized
username), and horn's boot-to-writing-tool behavior likely needs its own
greetd/session wiring distinct from silk's Sway session (see the
greetd/tuigreet items in [[dotfiles-and-editor|Dotfiles and editor]], which
currently assume one generic session) - plus deciding what the writing tool
actually is, which isn't settled yet.
