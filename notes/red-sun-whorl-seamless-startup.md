# Seamless themed startup process for red-sun-whorl

Goal: the entire process from hitting the power button to logging in as
silk should feel like one continuous, themed cutscene - not a sequence of
visually disjointed screens (stock boot logo, generic bootloader, plain
TUI login, then finally the Whorl-themed desktop). A few points of
interactivity are fine as long as they don't break the fiction by default -
e.g. a "press any key to skip" / "press Del for settings" hint that only
appears in the corners once a key is actually pressed, not shown
unprompted.

Current state (as of this note): only the desktop wallpaper
(`modules/themes/red-sun-whorl-wallpaper.nix`) actually depicts the Whorl.
Everything upstream of the desktop - systemd-boot, Plymouth (`oreb`, just
recolored to the Ancient Ruins palette, no Whorl imagery), and
greetd/tuigreet (generic ASCII, colors stubbed) - is generic-terminal
themed at best.

Stages, roughly in boot order:

- [ ] [[red-sun-whorl-boot-logo|Custom UEFI boot logo]] - the very first
      thing visible after the power button, before systemd-boot or
      Plymouth even run. Firmware-level, independent of everything else
      below.
- [ ] systemd-boot menu / kernel handoff - currently stock, including the
      NixOS generation (build history) selection list itself. Needs at
      least a color-matched background so there's no flash at the
      boundary to Plymouth. This list is also the natural home for the
      "press Del for settings"-style interactivity from the original
      brainstorm - it's already the closest thing this system has to a
      boot settings screen, just themed generically today.
- [ ] Plymouth boot splash - currently `oreb`
      (`modules/plymouth-oreb.nix`), just recolored, not Whorl-themed.
      Candidate: animate the wallpaper's sun-line motif, sun position
      tied to boot progress.
- [ ] greetd/tuigreet login - currently generic ASCII
      (`modules/tuigreet-theme.nix`, `modules/greetd-hyprland.nix`).
      Open question from brainstorming: stay TUI-consistent (matches the
      retro/terminal aesthetic already used elsewhere via NEWT_COLORS/
      console theming) vs. switch to a graphical Wayland greeter (e.g.
      regreet) that can show the actual wallpaper scene continuously
      instead of a hard cut to a TUI.
- [ ] Hyprland session start - hyprpaper sets the real wallpaper here;
      check for pop-in/flash before it loads.

Not yet decided: which of the middle stages (systemd-boot / Plymouth /
greeter) to tackle next, or whether to settle the TUI-vs-graphical-greeter
question first since it affects how much of the later work is worth doing
twice.
