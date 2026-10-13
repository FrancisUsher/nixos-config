import QtQuick

Item {
    id: root

    required property var modelData
    required property url sheet
    required property real pixelScale
    property real originX: 0
    property real originY: 0

    readonly property real cell: 8 * pixelScale

    function phase(v) {
        return ((v % root.cell) + root.cell) % root.cell;
    }

    x: modelData.x
    y: modelData.y
    width: modelData.w
    height: modelData.h
    clip: true

    Image {
        x: root.modelData.aligned ? -root.phase(root.originX + root.modelData.x) : 0
        y: root.modelData.aligned ? -root.phase(root.originY + root.modelData.y) : 0
        width: Math.ceil((root.width - x) / root.pixelScale)
        height: Math.ceil((root.height - y) / root.pixelScale)
        scale: root.pixelScale
        transformOrigin: Item.TopLeft
        source: root.sheet
        sourceClipRect: Qt.rect((root.modelData.tile % 4) * 8, Math.floor(root.modelData.tile / 4) * 8, 8, 8)
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        smooth: false
    }
}
