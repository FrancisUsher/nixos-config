import QtQuick

Item {
    id: root

    required property var theme
    property string label: ""
    property bool checked: false

    width: parent ? parent.width : 0
    height: 24

    // radio-style indicator showing whether this option is the active one
    Rectangle {
        id: dot
        width: 12
        height: 12
        radius: 6
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        border.width: 1
        border.color: root.enabled ? root.theme.hex("base05") : root.theme.hex("base03")
        color: root.checked ? root.theme.hex("base0A") : "transparent"
    }

    // the option's name, next to its indicator
    Text {
        anchors.left: dot.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.enabled ? root.theme.hex("base05") : root.theme.hex("base03")
    }
}
