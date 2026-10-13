import QtQuick

Rectangle {
    id: root

    required property var theme
    property real volume: 0
    property bool muted: false

    color: root.theme.hex("base00")
    border.color: root.theme.hex("base02")
    border.width: 1
    radius: 8

    Text {
        id: label
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        text: root.muted ? "mute" : Math.round(root.volume * 100)
        color: root.theme.hex("base04")
        font.pixelSize: 11
    }

    Rectangle {
        id: track
        anchors.left: label.right
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        radius: 2
        color: root.theme.hex("base02")
    }

    Rectangle {
        anchors.left: track.left
        anchors.verticalCenter: track.verticalCenter
        width: track.width * Math.min(1, root.volume)
        height: 4
        radius: 2
        color: root.muted ? root.theme.hex("base03") : root.theme.hex("base0A")
    }
}
