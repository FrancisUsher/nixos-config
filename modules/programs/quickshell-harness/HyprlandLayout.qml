import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property var clients: []
    property var monitors: []

    function refresh() {
        if (root.active && !query.running) query.running = true;
    }

    onActiveChanged: refresh()

    Process {
        id: query
        command: ["sh", "-c", "printf '{\"clients\":'; hyprctl -j clients; printf ',\"monitors\":'; hyprctl -j monitors; printf '}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    root.clients = data.clients;
                    root.monitors = data.monitors;
                } catch (e) {
                    console.warn("border-harness: could not parse hyprctl layout", e);
                }
            }
        }
    }

    Timer {
        id: eventDebounce
        interval: 30
        onTriggered: root.refresh()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            eventDebounce.restart();
        }
    }
}
