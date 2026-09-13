import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    PanelWindow {
        id: window
        visible: false

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "display-options"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        anchors {
            top: true
            right: true
        }
        margins {
            top: 40
            right: 20
        }

        implicitWidth: 340
        implicitHeight: 220

        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e"
            border.color: "#585b70"
            border.width: 1
            radius: 8

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Text {
                    text: "Display options"
                    color: "#cdd6f4"
                    font.pixelSize: 18
                    font.bold: true
                }

                Text {
                    text: "Border render mode: (harness stub - modes land here)"
                    color: "#a6adc8"
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
        }
    }

    IpcHandler {
        target: "displayOptions"

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
