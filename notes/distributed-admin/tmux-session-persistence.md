# tmux session persistence across reboots

The existing auto-attach hook (remote-operations.nix's
programs.bash/zsh.interactiveShellInit, `tmux attach -t main || tmux new -s
main`) already survives a *dropped connection* - reattach and the session
is still there. It does not survive the tmux server itself dying, which is
exactly what happens on a reboot: the process tree is gone, so `tmux new -s
main` just starts empty.

- [ ] Add tmux-resurrect (save/restore pane layout + running programs) and
      tmux-continuum (autosave on an interval + optional auto-restore on
      tmux server start) to programs.tmux's plugin list in
      remote-operations.nix
- [ ] Decide autosave interval and whether restore should be automatic on
      first `tmux new -s main` after a reboot, or a manual `prefix + Ctrl-r`
      - automatic is more "just works" but means silently reviving whatever
        was running (including any long-lived Claude Code CLI sessions) on
        every fresh boot, which may not always be wanted
- [ ] Check what tmux-resurrect actually restores for panes that were
      running a REPL/CLI (like `claude`) rather than a shell - it typically
      restores the pane's working directory and can be told to re-run a
      specific command, but won't resume in-process conversation state
