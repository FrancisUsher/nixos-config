import QtQuick

Rectangle {
    id: root

    required property var theme
    required property string modelData
    property string slot: ""
    property bool selected: false
    signal picked()

    width: 24
    height: 24
    radius: 4
    color: theme.hex(slot)
    border.width: selected ? 2 : 1
    border.color: selected ? theme.hex("base06") : theme.hex("base02")

    MouseArea {
        anchors.fill: parent
        onClicked: root.picked()
    }
}
