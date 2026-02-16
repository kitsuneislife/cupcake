// main.qml — entry point for the example QuickShell configuration
// Minimal placeholder — replace with your real QML UI pieces.
import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: root
    visible: true
    width: 600
    height: 40
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: "#20202088"
        radius: 4

        Text {
            anchors.centerIn: parent
            text: "QuickShell — example top bar"
            color: "#ffffff"
            font.pixelSize: 14
        }
    }
}
