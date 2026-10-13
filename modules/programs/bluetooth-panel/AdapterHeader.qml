import QtQuick
import Quickshell.Bluetooth

Item {
    id: root

    required property var theme
    property BluetoothAdapter adapter

    width: parent ? parent.width : 0
    height: 28

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "Bluetooth"
        color: root.theme.hex("base06")
        font.pixelSize: 18
        font.bold: true
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        TextButton {
            theme: root.theme
            visible: root.adapter?.enabled ?? false
            label: root.adapter?.discovering ? "Stop" : "Scan"
            active: root.adapter?.discovering ?? false
            onClicked: root.adapter.discovering = !root.adapter.discovering
        }

        TextButton {
            theme: root.theme
            enabled: root.adapter !== null
            label: !root.adapter ? "No adapter" : root.adapter.enabled ? "On" : "Off"
            active: root.adapter?.enabled ?? false
            onClicked: root.adapter.enabled = !root.adapter.enabled
        }
    }
}
