import QtQuick

Rectangle {
    id: root

    required property var theme
    property string label: ""
    property bool active: false
    signal clicked()

    implicitWidth: labelText.implicitWidth + 16
    implicitHeight: 20
    radius: 4
    color: root.active ? root.theme.hex("base02") : "transparent"
    border.width: 1
    border.color: !root.enabled ? root.theme.hex("base02")
        : mouse.containsMouse ? root.theme.hex("base05") : root.theme.hex("base03")

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: !root.enabled ? root.theme.hex("base03")
            : root.active ? root.theme.hex("base0A") : root.theme.hex("base05")
        font.pixelSize: 11
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
