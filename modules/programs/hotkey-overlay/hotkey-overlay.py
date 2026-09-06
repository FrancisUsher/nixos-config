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


def prettify_description(desc):
    if desc.startswith("exec "):
        desc = desc[len("exec "):]
    return desc.strip()


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


def build_tile(combo, desc):
    tile = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    tile.get_style_context().add_class("hotkey-tile")

    combo_label = Gtk.Label(label=combo, xalign=0)
    combo_label.get_style_context().add_class("hotkey-combo")
    tile.pack_start(combo_label, False, False, 0)

    desc_label = Gtk.Label(label=desc, xalign=0)
    desc_label.set_line_wrap(True)
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
    window.set_default_size(int(geometry.width * 0.7), int(geometry.height * 0.7))

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
