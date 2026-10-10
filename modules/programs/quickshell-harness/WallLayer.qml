pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "WallGeometry.js" as WallGeometry

PanelWindow {
    id: root

    required property var modelData
    required property var clients
    required property var monitors
    required property var wallOptions
    required property url sheet

    readonly property var monitor: monitors.find(m => m.name === modelData.name) ?? null
    readonly property var wallLayout: WallGeometry.forMonitor(clients, monitor, modelData.width, modelData.height, wallOptions)

    screen: modelData
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "border-wall"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Repeater {
        model: root.wallLayout.fills.concat(root.wallLayout.pieces)

        TileStrip {
            sheet: root.sheet
            pixelScale: root.wallOptions.pixelScale
            originX: root.monitor ? root.monitor.x : 0
            originY: root.monitor ? root.monitor.y : 0
        }
    }
}
