# GitHub CLI

Independent - doesn't need [[home-manager|Home Manager]].

- [x] Install `gh` - via home.nix's programs.gh (see
      [[dotfiles-and-editor|Dotfiles and editor]])
- [x] Authenticate - `gh auth login` done manually (account FrancisUsher,
      repo/gist/read:org scopes). Deliberately not declarative, since
      hosts.yml holds a live oauth token in plaintext - see the note in
      [[dotfiles-and-editor|Dotfiles and editor]]'s "Port gh config" item.
