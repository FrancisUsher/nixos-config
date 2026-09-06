#!/usr/bin/env python3

import json
import re
import subprocess
import sys

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")

from gi.repository import Gdk, Gtk, GtkLayerShell

MOD_NAMES = {
    "Mod4": "Super",
    "Mod1": "Alt",
    "Control": "Ctrl",
    "Ctrl": "Ctrl",
    "Shift": "Shift",
}

BIND_RE = re.compile(r"^(?:bindsym|bindcode)\s+(?:--\S+\s+)*(\S+)\s+(.+)$")
SET_RE = re.compile(r"^set\s+(\$\S+)\s+(.+?)\s*$")

DESC_RULES = [
    (re.compile(r"^workspace number (\d+)$"), lambda m: f"Workspace {m.group(1)}"),
    (re.compile(r"^move container to workspace number (\d+)$"), lambda m: f"Move to workspace {m.group(1)}"),
    (re.compile(r"^focus (left|right|up|down)$"), lambda m: f"Focus {m.group(1)}"),
    (re.compile(r"^move (left|right|up|down)$"), lambda m: f"Move {m.group(1)}"),
    (re.compile(r"^move scratchpad$"), lambda m: "Move to scratchpad"),
    (re.compile(r"^scratchpad show$"), lambda m: "Show scratchpad"),
    (re.compile(r"^focus parent$"), lambda m: "Focus parent"),
    (re.compile(r"^focus mode_toggle$"), lambda m: "Toggle focus mode"),
    (re.compile(r"^layout stacking$"), lambda m: "Stacking layout"),
    (re.compile(r"^layout tabbed$"), lambda m: "Tabbed layout"),
    (re.compile(r"^layout toggle split$"), lambda m: "Toggle split layout"),
    (re.compile(r"^splith$"), lambda m: "Split horizontal"),
    (re.compile(r"^splitv$"), lambda m: "Split vertical"),
    (re.compile(r"^fullscreen toggle$"), lambda m: "Toggle fullscreen"),
    (re.compile(r"^floating toggle$"), lambda m: "Toggle floating"),
    (re.compile(r"^kill$"), lambda m: "Close window"),
    (re.compile(r"^reload$"), lambda m: "Reload config"),
    (re.compile(r"^mode resize$"), lambda m: "Resize mode"),
    (re.compile(r"^mode default$"), lambda m: "Exit resize mode"),
    (re.compile(r"^resize grow height"), lambda m: "Grow height"),
    (re.compile(r"^resize shrink height"), lambda m: "Shrink height"),
    (re.compile(r"^resize grow width"), lambda m: "Grow width"),
    (re.compile(r"^resize shrink width"), lambda m: "Shrink width"),
    (re.compile(r"^exec grim$"), lambda m: "Screenshot"),
    (re.compile(r"^exec wpctl set-volume \S+ 5%-$"), lambda m: "Volume down"),
    (re.compile(r"^exec wpctl set-volume \S+ 5%\+$"), lambda m: "Volume up"),
    (re.compile(r"^exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle$"), lambda m: "Toggle mic mute"),
    (re.compile(r"^exec wpctl set-mute \S+ toggle$"), lambda m: "Toggle mute"),
    (re.compile(r"^exec brightnessctl set 5%-$"), lambda m: "Brightness down"),
    (re.compile(r"^exec brightnessctl set 5%\+$"), lambda m: "Brightness up"),
    (re.compile(r"^exec kitty$"), lambda m: "Open terminal"),
    (re.compile(r"^exec fuzzel$"), lambda m: "Open launcher"),
    (re.compile(r"^exec fuzzel-cliphist$"), lambda m: "Clipboard history"),
    (re.compile(r"fuzzel-cliphist.*wtype"), lambda m: "Paste from history"),
    (re.compile(r"^exec swaynag.*exit sway"), lambda m: "Exit sway"),
]

CSS = b"""
.hotkey-overlay {
    border: 4px solid @borders;
    background-color: @theme_bg_color;
}
.hotkey-title {
    font-weight: bold;
    font-size: 1.4em;
    padding: 12px;
}
.hotkey-tile {
    border: 1px solid @borders;
    padding: 8px;
}
.hotkey-combo {
    font-family: monospace;
    font-weight: bold;
}
.hotkey-desc {
    opacity: 0.75;
}
"""


def get_sway_config():
    try:
        result = subprocess.run(
            ["swaymsg", "-t", "get_config", "--raw"],
            capture_output=True,
            text=True,
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        sys.exit(f"hotkey-overlay: couldn't read sway config: {exc}")
    return json.loads(result.stdout)["config"]


def substitute_vars(combo, variables):
    for name in sorted(variables, key=len, reverse=True):
        combo = combo.replace(name, variables[name])
    return combo


def prettify_combo(combo):
    parts = [MOD_NAMES.get(part, part) for part in combo.split("+")]
    return " + ".join(parts)


def shorten_exec(cmd):
    token = cmd.split()[0] if cmd.split() else cmd
    match = re.match(r"^/nix/store/[a-z0-9]+-(.+)$", token)
    if match:
        rest = match.group(1)
        token = rest.split("/bin/")[-1] if "/bin/" in rest else rest.split("/")[0]
    token = re.sub(r"-[\d.]+$", "", token)
    token = token.replace("-", " ").replace("_", " ").strip()
    return token.title() if token else cmd


def prettify_description(desc):
    desc = desc.strip()
    for pattern, handler in DESC_RULES:
        match = pattern.search(desc)
        if match:
            return handler(match)
    if desc.startswith("exec "):
        return shorten_exec(desc[len("exec "):])
    return " ".join(desc.split()[:3]).capitalize()


def load_bindings():
    config_text = get_sway_config()

    variables = {}
    for line in config_text.splitlines():
        match = SET_RE.match(line.strip())
        if match:
            variables[match.group(1)] = match.group(2)

    bindings = []
    depth = 0
    for line in config_text.splitlines():
        stripped = line.strip()
        if depth == 0:
            match = BIND_RE.match(stripped)
            if match:
                combo_raw, desc = match.groups()
                combo = prettify_combo(substitute_vars(combo_raw, variables))
                desc = prettify_description(substitute_vars(desc, variables))
                bindings.append((combo, desc))
        depth += stripped.count("{") - stripped.count("}")

    return bindings


TILE_WIDTH = 150


def build_tile(combo, desc):
    tile = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    tile.get_style_context().add_class("hotkey-tile")
    tile.set_size_request(TILE_WIDTH, -1)

    combo_label = Gtk.Label(label=combo, xalign=0)
    combo_label.set_line_wrap(True)
    combo_label.set_max_width_chars(1)
    combo_label.get_style_context().add_class("hotkey-combo")
    tile.pack_start(combo_label, False, False, 0)

    desc_label = Gtk.Label(label=desc, xalign=0)
    desc_label.set_line_wrap(True)
    desc_label.set_max_width_chars(1)
    desc_label.get_style_context().add_class("hotkey-desc")
    tile.pack_start(desc_label, False, False, 0)

    return tile


def build_window(bindings):
    window = Gtk.Window()
    GtkLayerShell.init_for_window(window)
    GtkLayerShell.set_namespace(window, "hotkey-overlay")
    GtkLayerShell.set_layer(window, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_keyboard_mode(window, GtkLayerShell.KeyboardMode.EXCLUSIVE)

    monitor = Gdk.Display.get_default().get_primary_monitor()
    if monitor is None:
        monitor = Gdk.Display.get_default().get_monitor(0)
    geometry = monitor.get_geometry()
    width = int(geometry.width * 0.7)
    height = int(geometry.height * 0.7)
    window.set_size_request(width, height)
    window.set_default_size(width, height)

    outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    outer.get_style_context().add_class("hotkey-overlay")
    window.add(outer)

    title = Gtk.Label(label="Sway Hotkeys")
    title.get_style_context().add_class("hotkey-title")
    outer.pack_start(title, False, False, 0)

    flow_box = Gtk.FlowBox()
    flow_box.set_valign(Gtk.Align.START)
    flow_box.set_selection_mode(Gtk.SelectionMode.NONE)
    flow_box.set_homogeneous(True)
    flow_box.set_min_children_per_line(1)
    flow_box.set_max_children_per_line(max(1, width // TILE_WIDTH))
    flow_box.set_row_spacing(8)
    flow_box.set_column_spacing(8)
    flow_box.set_margin_start(12)
    flow_box.set_margin_end(12)
    flow_box.set_margin_bottom(12)

    for combo, desc in bindings:
        flow_box.insert(build_tile(combo, desc), -1)

    scroller = Gtk.ScrolledWindow()
    scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
    scroller.add(flow_box)
    outer.pack_start(scroller, True, True, 0)

    window.connect("destroy", Gtk.main_quit)
    window.connect("key-press-event", on_key_press)

    return window


def on_key_press(window, event):
    if event.keyval == Gdk.KEY_Escape:
        Gtk.main_quit()


def main():
    bindings = load_bindings()

    style_provider = Gtk.CssProvider()
    style_provider.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        style_provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
    )

    window = build_window(bindings)
    window.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
