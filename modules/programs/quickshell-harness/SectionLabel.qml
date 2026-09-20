import QtQuick

Text {
    required property var theme

    color: theme.hex("base04")
    font.pixelSize: 12
    font.bold: true
    font.capitalization: Font.AllUppercase
}
