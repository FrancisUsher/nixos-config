# Build warnings to clean up

Noticed during `nix flake check` / `nixos-rebuild build` for both hosts on
the current pins (nixpkgs 26.05 / home-manager release-26.05 / nixvim
nixos-26.05). None are build failures - just deprecation notices worth
clearing before they become breakage on a future bump.

- [ ] `nixvim: flake output 'homeManagerModules' has been renamed to
      'homeModules'.` - `flake.nix:42` still uses
      `nixvim.homeManagerModules.nixvim`; switch to `nixvim.homeModules.nixvim`.
- [ ] `The 'home-manager.users.<user>.programs.nixvim.nixpkgs.source' default
      value has been affected by your flake input 'follows'.` (shown for both
      soong and silk profiles) - nixvim's own inputs pin a different nixpkgs
      rev than the one `inputs.nixvim.inputs.nixpkgs.follows = "nixpkgs"` in
      `flake.nix` forces it to use. Either drop that `follows` line, or set
      `programs.nixvim.nixpkgs.source` explicitly (per-user, in
      `modules/nixvim.nix`) to silence it intentionally.
- [ ] `'programs.ssh' default values will be removed in the future.` (shown
      for both profiles) - `modules/programs/ssh.nix` only sets
      `settings."bubu-brain*".User`; home-manager wants
      `programs.ssh.enableDefaultConfig = false` plus moving any defaults
      we're relying on into `programs.ssh.settings."*"` explicitly.
