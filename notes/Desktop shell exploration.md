# Desktop shell exploration

Low priority, after initial dotfile porting.

- [ ] Investigate quickshell as a possible replacement for the waybar/
      swaylock/mako stack. QML-based, single persistent process instead of
      several small ones - more flexible than waybar's JSON+CSS but likely
      higher idle RAM (Qt/QML runtime); unmeasured, so benchmark before
      actually switching rather than assuming.
