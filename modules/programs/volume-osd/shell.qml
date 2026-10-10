import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    property real volume: 0
    property bool muted: false
    property bool primed: false

    function sync() {
        if (!root.sink || !root.sink.ready || !root.sink.audio)
            return;
        const v = root.sink.audio.volume;
        const m = root.sink.audio.muted;
        const changed = v !== root.volume || m !== root.muted;
        root.volume = v;
        root.muted = m;
        if (root.primed && changed) {
            window.visible = true;
            hideTimer.restart();
        }
        root.primed = true;
    }

    onSinkChanged: {
        root.primed = false;
        root.sync();
    }

    Theme {
        id: theme
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Connections {
        target: root.sink
        ignoreUnknownSignals: true
        function onReadyChanged() { root.sync(); }
    }

    Connections {
        target: root.sink ? root.sink.audio : null
        ignoreUnknownSignals: true
        function onVolumesChanged() { root.sync(); }
        function onMutedChanged() { root.sync(); }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: window.visible = false
    }

    PanelWindow {
        id: window
        visible: false
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "volume-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.bottom: true
        margins.bottom: 80

        implicitWidth: 240
        implicitHeight: 32

        mask: Region {}

        VolumeBar {
            anchors.fill: parent
            theme: theme
            volume: root.volume
            muted: root.muted
        }
    }
}
