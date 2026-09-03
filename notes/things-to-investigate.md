# Things to investigate

Low priority, no immediate need.

- [ ] Investigate quickshell as a possible replacement for the waybar/
      swaylock/mako stack. QML-based, single persistent process instead of
      several small ones - more flexible than waybar's JSON+CSS but likely
      higher idle RAM (Qt/QML runtime); unmeasured, so benchmark before
      actually switching rather than assuming.
- [ ] Investigate atuin for shell history, instead of/alongside plain zsh
      history. Its one differentiator over what's already planned (fzf's
      Ctrl+R fuzzy search, already covered) is cross-host history sync
      between bubu-brain and red-sun-whorl - worth it only if that's
      actually wanted day to day. Costs: contests Ctrl+R with fzf's zsh
      integration (fixable, but a real conflict to resolve), moves history
      into a SQLite db it owns instead of a plain HISTFILE, and needs
      either trusting atuin's hosted sync or running your own sync server.
      No need to decide now - the zsh port (see
      [[dotfiles-and-editor|Dotfiles and editor]]) uses plain zsh history
      until/unless this gets picked up.
