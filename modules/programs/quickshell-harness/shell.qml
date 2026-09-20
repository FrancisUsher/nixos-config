pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    property string selectedAccent: "base09"
    property real stoneBlend: 0.20
    property real highlightBlend: 0.45

    function regenerate() {
        Quickshell.execDetached([
            "border-harness-generate",
            "--accent", root.selectedAccent,
            "--stone-blend", root.stoneBlend.toFixed(2),
            "--highlight-blend", root.highlightBlend.toFixed(2)
        ]);
    }

    Theme {
        id: theme
    }

    Timer {
        id: regenDebounce
        interval: 300
        onTriggered: root.regenerate()
    }

    FileView {
        id: selectionFile
        path: Quickshell.env("HOME") + "/.config/border-harness/selection.json"
        preload: true
        blockLoading: true
    }

    Component.onCompleted: {
        try {
            const saved = JSON.parse(selectionFile.text());
            root.selectedAccent = saved.accent;
            root.stoneBlend = saved.stone_blend;
            root.highlightBlend = saved.highlight_blend;
        } catch (e) {
            console.warn("border-harness: could not load saved selection, using built-in defaults", e);
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
            color: theme.hex("base00")
            border.color: theme.hex("base02")
            border.width: 1
            radius: 8

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                Text {
                    text: "Display options"
                    color: theme.hex("base06")
                    font.pixelSize: 18
                    font.bold: true
                }

                Column {
                    width: parent.width
                    spacing: 4

                    SectionLabel { theme: theme; text: "Algorithm" }
                    OptionRow { theme: theme; label: "Repeating sprite"; checked: true; enabled: true }
                    OptionRow { theme: theme; label: "Neighbor-aware autotile (soon)"; checked: false; enabled: false }
                    OptionRow { theme: theme; label: "Procedural generation (soon)"; checked: false; enabled: false }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    SectionLabel { theme: theme; text: "Sprite" }
                    OptionRow { theme: theme; label: "Ancient Ruins brick"; checked: true; enabled: true }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    SectionLabel { theme: theme; text: "Color theming" }

                    Row {
                        spacing: 6
                        Repeater {
                            model: ["base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F"]
                            Swatch {
                                theme: theme
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

                        Text { text: "Stone brightness"; color: theme.hex("base04"); font.pixelSize: 11 }
                        ParamSlider {
                            theme: theme
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

                        Text { text: "Highlight brightness"; color: theme.hex("base04"); font.pixelSize: 11 }
                        ParamSlider {
                            theme: theme
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
