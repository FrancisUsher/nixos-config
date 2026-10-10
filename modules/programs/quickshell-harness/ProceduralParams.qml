import QtQuick

Column {
    id: root

    required property var theme
    property int seed: 1
    property real roughness: 0.5
    property real chipping: 0.4
    property real moss: 0.2
    property bool merge: true
    signal edited(string key, var value)

    width: parent ? parent.width : 0
    spacing: 8

    SectionLabel { theme: root.theme; text: "Procedural" }

    Row {
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Seed " + root.seed
            color: root.theme.hex("base05")
            font.pixelSize: 12
        }

        Rectangle {
            id: reroll
            width: rerollLabel.implicitWidth + 16
            height: 22
            radius: 4
            color: root.theme.hex("base01")
            border.width: activeFocus ? 2 : 1
            border.color: activeFocus ? root.theme.hex("base0A") : root.theme.hex("base02")
            activeFocusOnTab: true

            function fire() {
                root.edited("seed", Math.floor(Math.random() * 1000000));
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    reroll.fire();
                    event.accepted = true;
                }
            }

            Text {
                id: rerollLabel
                anchors.centerIn: parent
                text: "Reroll"
                color: root.theme.hex("base06")
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: { reroll.forceActiveFocus(); reroll.fire(); }
            }
        }
    }

    Text { text: "Roughness"; color: root.theme.hex("base04"); font.pixelSize: 11 }
    ParamSlider {
        theme: root.theme
        value: root.roughness
        onMoved: root.edited("roughness", value)
    }

    Text { text: "Chipping"; color: root.theme.hex("base04"); font.pixelSize: 11 }
    ParamSlider {
        theme: root.theme
        value: root.chipping
        onMoved: root.edited("chipping", value)
    }

    Text { text: "Moss"; color: root.theme.hex("base04"); font.pixelSize: 11 }
    ParamSlider {
        theme: root.theme
        value: root.moss
        onMoved: root.edited("moss", value)
    }

    OptionRow {
        theme: root.theme
        label: "Merge adjoining walls"
        checked: root.merge
        onPicked: root.edited("merge", !root.merge)
    }
}
