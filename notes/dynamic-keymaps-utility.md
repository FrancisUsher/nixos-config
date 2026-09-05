# Dynamic keymaps utility

A cheat-sheet tool that shows the keymaps actually available right now,
based on which applications currently have focus/are open (e.g. sway
bindings vs. the active app's own bindings vs. tmux prefix table), rather
than one static reference that mixes everything together.

- [ ] Figure out how to detect "what's open/focused" (sway IPC for window
      class/focus, tmux for pane context, etc.)
- [ ] Decide on a source of truth for each app's keymaps (parse config
      where possible - sway config, tmux config - vs. hand-maintained
      lists for apps that don't expose theirs declaratively)
- [ ] Decide on presentation - overlay/popup triggered by a key, or a
      terminal command
