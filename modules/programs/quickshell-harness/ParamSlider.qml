import QtQuick

Item {
    id: root

    required property var theme
    property real value: 0.5
    property real from: 0
    property real to: 1
    property real step: (to - from) / 20
    signal moved()

    function setValue(v) {
        root.value = Math.max(root.from, Math.min(root.to, v));
        root.moved();
    }

    width: parent ? parent.width : 0
    height: 16
    activeFocusOnTab: true

    Keys.onLeftPressed: root.setValue(root.value - root.step)
    Keys.onRightPressed: root.setValue(root.value + root.step)

    // the full [from, to] span the slider covers
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: root.theme.hex("base02")
    }
    // the portion of the track below the current value
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: track.width * ((root.value - root.from) / (root.to - root.from))
        height: 4
        radius: 2
        color: root.theme.hex("base0A")
    }
    // what the user grabs to move the slider
    Rectangle {
        id: handle
        width: 12
        height: 12
        radius: 6
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(track.width - width,
            track.width * ((root.value - root.from) / (root.to - root.from)) - width / 2))
        color: root.theme.hex("base06")
        border.width: root.activeFocus ? 2 : 0
        border.color: root.theme.hex("base0A")
    }
    // clicking or dragging anywhere on the slider jumps/drags the value
    MouseArea {
        anchors.fill: parent

        function setFromX(mx) {
            let t = Math.max(0, Math.min(1, mx / width));
            root.setValue(root.from + t * (root.to - root.from));
        }

        onPressed: (mouse) => { root.forceActiveFocus(); setFromX(mouse.x); }
        onPositionChanged: (mouse) => { if (pressed) setFromX(mouse.x); }
    }
}
