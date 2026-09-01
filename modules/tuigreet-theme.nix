# Inert color-derivation stub for tuigreet - not wired to a running greeter
# yet. See TODO.md: neither host has a compositor session to launch into
# (blocked on "port sway" / "sway desktop config"), so this only prepares the
# color piece for when that lands.
#
# tuigreet's --theme flag only accepts named ANSI colors (ratatui's
# black/red/green/yellow/blue/magenta/cyan/gray/darkgray/light*/white), not
# arbitrary hex - so this can't pull hex straight out of
# config.lib.stylix.colors the way most Stylix targets do. Instead it relies
# on stylix.targets.console (enabled in modules/stylix.nix) having already
# remapped the TTY's 16 ANSI color slots to the Ancient Ruins base16 scheme:
# picking "green" below will render as this theme's actual green
# (base0B, #76856a) once console theming is active on the TTY tuigreet runs
# on, with no hex needed at all.
#
# Once a greeter session exists, wire config.lib.tuigreet.themeArg into the
# tuigreet invocation inside services.greetd.settings.default_session.command.
{ lib, ... }:

{
  config.lib.tuigreet.themeArg = lib.concatStringsSep ";" (lib.mapAttrsToList (k: v: "${k}=${v}") {
    border = "darkgray";
    text = "white";
    prompt = "green";
    time = "cyan";
    action = "blue";
    button = "magenta";
    container = "black";
    input = "blue";
  });
}
