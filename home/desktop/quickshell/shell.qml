// shell.qml — QuickShell expects this filename (or a `default/` dir with shell.qml)
// Copied from `main.qml` as a minimal, valid shell entry point.
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
