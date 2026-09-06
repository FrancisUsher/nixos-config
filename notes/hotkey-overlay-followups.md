# Hotkey overlay follow-ups

Sway-only GTK popover (`modules/programs/hotkey-overlay.nix`) is a working
MVP. Next steps to make it more useful:

- [ ] Tighten up per-tile layout - still wasting space even with the
      compact tiles and shortened descriptions from the first pass.
- [ ] Add tabs to switch between hotkey sets for different apps. Start
      with a POC covering just one more app alongside Sway (e.g. tmux
      or the terminal/editor in focus) to prove out the multi-source
      model before generalizing.
- [ ] Figure out how to detect which app(s) to show hotkeys for
      automatically (sway IPC for focused window class, tmux for pane
      context, etc.) instead of manually flipping tabs.
- [ ] Add a way to filter the (currently comprehensive) key list down
      to just the subset someone actually wants to focus on
      learning/practicing - full reference is useful but overwhelming
      as a learning tool.
