import QtQuick

Rectangle {
    id: root

    required property var theme
    required property int index
    property string slot: ""
    property bool selected: false
    signal picked()

    width: 24
    height: 24
    radius: 4
    color: theme.hex(slot)
    border.width: (selected || activeFocus) ? 2 : 1
    border.color: (selected || activeFocus) ? theme.hex("base06") : theme.hex("base02")
    activeFocusOnTab: true

    // click this color to make it the accent
    MouseArea {
        anchors.fill: parent
        onClicked: { root.forceActiveFocus(); root.picked(); }
    }

    // Return/Space also picks this color, for keyboard use
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.picked();
            event.accepted = true;
        }
    }
}
