pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    property var palette: ({
        base00: "1c1b1a", base01: "262423", base02: "4a4733", base03: "7a7875",
        base04: "7a7875", base05: "b8b5b1", base06: "e3cba5", base07: "e3cba5",
        base08: "8c504a", base09: "9d5d40", base0A: "d4af37", base0B: "76856a",
        base0C: "6ab0c7", base0D: "c4824d", base0E: "846b97", base0F: "c2b280"
    })

    property string selectedAccent: "base09"
    property real stoneBlend: 0.20
    property real highlightBlend: 0.45

    function hex(slot) {
        return "#" + root.palette[slot];
    }

    function regenerate() {
        Quickshell.execDetached([
            "border-harness-generate",
            "--accent", root.selectedAccent,
            "--stone-blend", root.stoneBlend.toFixed(2),
            "--highlight-blend", root.highlightBlend.toFixed(2)
        ]);
    }

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.config/border-harness/palette.json"
        preload: true
        blockLoading: true
    }

    Timer {
        id: regenDebounce
        interval: 300
        onTriggered: root.regenerate()
    }

    component SectionLabel: Text {
        color: root.hex("base04")
        font.pixelSize: 12
        font.bold: true
        font.capitalization: Font.AllUppercase
    }

    component OptionRow: Item {
        property string label: ""
        property bool checked: false

        width: parent ? parent.width : 0
        height: 24

        Rectangle {
            id: dot
            width: 12
            height: 12
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            border.width: 1
            border.color: parent.enabled ? root.hex("base05") : root.hex("base03")
            color: parent.checked ? root.hex("base0A") : "transparent"
        }

        Text {
            anchors.left: dot.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: parent.enabled ? root.hex("base05") : root.hex("base03")
        }
    }

    component Swatch: Rectangle {
        id: swatch
        property string slot: ""
        property bool selected: false
        signal picked()

        width: 24
        height: 24
        radius: 4
        color: root.hex(slot)
        border.width: selected ? 2 : 1
        border.color: selected ? root.hex("base06") : root.hex("base02")

        MouseArea {
            anchors.fill: parent
            onClicked: swatch.picked()
        }
    }

    component ParamSlider: Item {
        id: sliderRoot
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
            color: root.hex("base02")
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: track.width * ((sliderRoot.value - sliderRoot.from) / (sliderRoot.to - sliderRoot.from))
            height: 4
            radius: 2
            color: root.hex("base0A")
        }
        Rectangle {
            id: handle
            width: 12
            height: 12
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width,
                track.width * ((sliderRoot.value - sliderRoot.from) / (sliderRoot.to - sliderRoot.from)) - width / 2))
            color: root.hex("base06")
        }
        MouseArea {
            anchors.fill: parent

            function setFromX(mx) {
                let t = Math.max(0, Math.min(1, mx / width));
                sliderRoot.value = sliderRoot.from + t * (sliderRoot.to - sliderRoot.from);
                sliderRoot.moved();
            }

            onPressed: (mouse) => setFromX(mouse.x)
            onPositionChanged: (mouse) => { if (pressed) setFromX(mouse.x); }
        }
    }

    Component.onCompleted: {
        try {
            root.palette = JSON.parse(paletteFile.text());
        } catch (e) {
            console.warn("border-harness: could not load palette.json, using built-in defaults", e);
        }
    }

    PanelWindow {
        id: window
        visible: false

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "display-options"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        anchors {
            top: true
            right: true
        }
        margins {
            top: 40
            right: 20
        }

        implicitWidth: 360
        implicitHeight: 440

        Rectangle {
            anchors.fill: parent
            color: root.hex("base00")
            border.color: root.hex("base02")
            border.width: 1
            radius: 8

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                Text {
                    text: "Display options"
                    color: root.hex("base06")
                    font.pixelSize: 18
                    font.bold: true
                }

                Column {
                    width: parent.width
                    spacing: 4

                    SectionLabel { text: "Algorithm" }
                    OptionRow { label: "Repeating sprite"; checked: true; enabled: true }
                    OptionRow { label: "Neighbor-aware autotile (soon)"; checked: false; enabled: false }
                    OptionRow { label: "Procedural generation (soon)"; checked: false; enabled: false }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    SectionLabel { text: "Sprite" }
                    OptionRow { label: "Ancient Ruins brick"; checked: true; enabled: true }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    SectionLabel { text: "Color theming" }

                    Row {
                        spacing: 6
                        Repeater {
                            model: ["base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F"]
                            Swatch {
                                slot: modelData
                                selected: root.selectedAccent === modelData
                                onPicked: {
                                    root.selectedAccent = modelData;
                                    regenDebounce.restart();
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 2

                        Text { text: "Stone brightness"; color: root.hex("base04"); font.pixelSize: 11 }
                        ParamSlider {
                            value: root.stoneBlend
                            from: 0.05
                            to: 0.6
                            onMoved: {
                                root.stoneBlend = value;
                                regenDebounce.restart();
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 2

                        Text { text: "Highlight brightness"; color: root.hex("base04"); font.pixelSize: 11 }
                        ParamSlider {
                            value: root.highlightBlend
                            from: 0.1
                            to: 0.9
                            onMoved: {
                                root.highlightBlend = value;
                                regenDebounce.restart();
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "displayOptions"

        function toggle(): void {
            window.visible = !window.visible;
        }

        function show(): void {
            window.visible = true;
        }

        function hide(): void {
            window.visible = false;
        }
    }
}
