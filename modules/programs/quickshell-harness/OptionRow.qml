import QtQuick

Item {
    id: root

    required property var theme
    property string label: ""
    property bool checked: false
    signal picked()

    width: parent ? parent.width : 0
    height: 24
    activeFocusOnTab: enabled

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.picked();
            event.accepted = true;
        }
    }

    // radio-style indicator showing whether this option is the active one
    Rectangle {
        id: dot
        width: 12
        height: 12
        radius: 6
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        border.width: root.activeFocus ? 2 : 1
        border.color: !root.enabled ? root.theme.hex("base03")
            : root.activeFocus ? root.theme.hex("base06") : root.theme.hex("base05")
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

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        onClicked: { root.forceActiveFocus(); root.picked(); }
    }
}
