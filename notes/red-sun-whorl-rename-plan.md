# red-sun-whorl rename plan

Referenced from [[migrate-arch-laptop-to-nixos|Migrate Arch laptop to NixOS]].

The laptop currently scaffolded as hosts/x1nano/ is planned to be renamed and
restructured, not just re-themed:

- Hostname becomes **red-sun-whorl**, after Gene Wolfe's Solar Cycle novels.
- Two separate Linux user accounts instead of bubu-brain's single "soong":
  - **silk** - general-purpose account, full GUI, Sway desktop (the "port
    sway config" etc. items in [[dotfiles-and-editor|Dotfiles and editor]] are for this user).
  - **horn** - a dedicated distraction-free writing space; boots straight
    into a writing tool and does essentially nothing else.

Why: the approach to this repo treats each host as a distinct
narrative/thematic experience, not just a functionally-tweaked variant.

How to apply: flake.nix's current `mkHost` helper wires a single
`home-manager.users.soong = import ./home.nix` per host - this breaks once
red-sun-whorl has two users. When this work starts: home.nix needs to split
into a shared base plus per-user configs (silk vs horn), the
x1nano hostname/user renaming needs to happen in
hosts/x1nano/configuration.nix, and horn's boot-to-writing-tool behavior
likely needs its own greetd/session wiring distinct from silk's Sway
session (see the greetd/tuigreet items in [[dotfiles-and-editor|Dotfiles and editor]], which
currently assume one generic session).
