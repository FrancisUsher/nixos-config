pragma ComponentBehavior: Bound
import QtQuick

Column {
    id: root

    required property var theme
    property string title: ""
    property var devices: []
    property string emptyText: ""

    width: parent ? parent.width : 0
    spacing: 4

    SectionLabel {
        theme: root.theme
        text: root.title
    }

    Text {
        visible: root.devices.length === 0
        text: root.emptyText
        color: root.theme.hex("base03")
        font.pixelSize: 11
    }

    Repeater {
        model: root.devices

        DeviceRow {
            required property var modelData
            theme: root.theme
            device: modelData
        }
    }
}
