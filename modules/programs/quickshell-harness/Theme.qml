import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: themeRoot

    property var colors: ({
        base00: "1c1b1a", base01: "262423", base02: "4a4733", base03: "7a7875",
        base04: "7a7875", base05: "b8b5b1", base06: "e3cba5", base07: "e3cba5",
        base08: "8c504a", base09: "9d5d40", base0A: "d4af37", base0B: "76856a",
        base0C: "6ab0c7", base0D: "c4824d", base0E: "846b97", base0F: "c2b280"
    })

    property var paletteFile: FileView {
        path: Quickshell.env("HOME") + "/.config/border-harness/palette.json"
        preload: true
        blockLoading: true
    }

    function hex(slot) {
        return "#" + themeRoot.colors[slot];
    }

    Component.onCompleted: {
        try {
            themeRoot.colors = JSON.parse(themeRoot.paletteFile.text());
        } catch (e) {
            console.warn("border-harness: could not load palette.json, using built-in defaults", e);
        }
    }
}
