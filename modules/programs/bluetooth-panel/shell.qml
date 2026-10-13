pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Bluetooth

ShellRoot {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var devices: Bluetooth.devices.values
    readonly property var known: root.devices
        .filter(d => d.paired || d.bonded)
        .sort((a, b) => b.connected - a.connected)
    readonly property var nearby: root.devices.filter(d => !d.paired && !d.bonded)

    Theme {
        id: theme
    }

    PanelWindow {
        id: window
        visible: false

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "bluetooth-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        anchors {
            top: true
            right: true
        }
        margins {
            top: 40
            right: 20
        }

        implicitWidth: 360
        implicitHeight: sections.implicitHeight + 32

        onVisibleChanged: {
            if (visible)
                content.forceActiveFocus();
            else if (root.adapter)
                root.adapter.discovering = false;
        }

        HyprlandFocusGrab {
            windows: [window]
            active: window.visible
            onCleared: window.visible = false
        }

        Rectangle {
            id: content
            anchors.fill: parent
            color: theme.hex("base00")
            border.color: theme.hex("base02")
            border.width: 1
            radius: 8
            focus: true

            Keys.onEscapePressed: window.visible = false

            Column {
                id: sections
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                AdapterHeader {
                    theme: theme
                    adapter: root.adapter
                }

                DeviceSection {
                    theme: theme
                    title: "Paired"
                    devices: root.known
                    visible: root.adapter?.enabled ?? false
                    emptyText: "No paired devices"
                }

                DeviceSection {
                    theme: theme
                    title: "Nearby"
                    devices: root.nearby
                    visible: root.adapter?.enabled ?? false
                    emptyText: root.adapter?.discovering ? "Searching…" : "Scan to find devices"
                }
            }
        }
    }

    IpcHandler {
        target: "bluetooth"

        function toggle(): void {
            window.visible = !window.visible;
        }

        function show(): void {
            window.visible = true;
        }

        function hide(): void {
            window.visible = false;
        }
    }
}
