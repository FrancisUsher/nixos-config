import QtQuick
import Quickshell.Bluetooth

Item {
    id: root

    required property var theme
    required property BluetoothDevice device
    property bool connectAfterPair: false

    readonly property bool known: root.device.paired || root.device.bonded
    readonly property bool busy: root.device.pairing
        || root.device.state === BluetoothDeviceState.Connecting
        || root.device.state === BluetoothDeviceState.Disconnecting

    readonly property string status: {
        if (root.device.pairing)
            return "pairing…";
        if (root.device.state === BluetoothDeviceState.Connecting)
            return "connecting…";
        if (root.device.state === BluetoothDeviceState.Disconnecting)
            return "disconnecting…";
        if (root.device.connected)
            return root.device.batteryAvailable ? "connected · " + Math.round(root.device.battery * 100) + "%" : "connected";
        return "";
    }

    function activate() {
        if (root.busy)
            return;
        if (root.device.connected) {
            root.device.disconnect();
        } else if (root.known) {
            root.device.connect();
        } else {
            root.connectAfterPair = true;
            root.device.pair();
        }
    }

    width: parent ? parent.width : 0
    height: 26
    activeFocusOnTab: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.activate();
            event.accepted = true;
        } else if (event.key === Qt.Key_Delete && root.known) {
            root.device.forget();
            event.accepted = true;
        }
    }

    Connections {
        target: root.device
        function onPairedChanged() {
            if (root.device.paired && root.connectAfterPair) {
                root.connectAfterPair = false;
                root.device.trusted = true;
                root.device.connect();
            }
        }
    }

    Rectangle {
        id: dot
        width: 12
        height: 12
        radius: 6
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? root.theme.hex("base06") : root.theme.hex("base05")
        color: root.device.connected ? root.theme.hex("base0A")
            : root.busy ? root.theme.hex("base03") : "transparent"
    }

    Text {
        anchors.left: dot.right
        anchors.leftMargin: 8
        anchors.right: statusText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.device.name || root.device.address
        elide: Text.ElideRight
        color: root.theme.hex("base05")
    }

    Text {
        id: statusText
        anchors.right: forget.visible ? forget.left : parent.right
        anchors.rightMargin: forget.visible ? 8 : 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.status
        color: root.theme.hex("base04")
        font.pixelSize: 11
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.forceActiveFocus();
            root.activate();
        }
    }

    TextButton {
        id: forget
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        theme: root.theme
        visible: root.known
        label: "forget"
        onClicked: root.device.forget()
    }
}
