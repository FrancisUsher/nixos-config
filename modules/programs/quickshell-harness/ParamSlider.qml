import QtQuick

Item {
    id: root

    required property var theme
    property real value: 0.5
    property real from: 0
    property real to: 1
    signal moved()

    width: parent ? parent.width : 0
    height: 16

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: root.theme.hex("base02")
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: track.width * ((root.value - root.from) / (root.to - root.from))
        height: 4
        radius: 2
        color: root.theme.hex("base0A")
    }
    Rectangle {
        id: handle
        width: 12
        height: 12
        radius: 6
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(track.width - width,
            track.width * ((root.value - root.from) / (root.to - root.from)) - width / 2))
        color: root.theme.hex("base06")
    }
    MouseArea {
        anchors.fill: parent

        function setFromX(mx) {
            let t = Math.max(0, Math.min(1, mx / width));
            root.value = root.from + t * (root.to - root.from);
            root.moved();
        }

        onPressed: (mouse) => setFromX(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) setFromX(mouse.x); }
    }
}
