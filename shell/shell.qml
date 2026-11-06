import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            color: "#000000"
            WlrLayershell.layer: WlrLayer.Background
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
        }

        PanelWindow {
            required property var modelData
            screen: modelData
            color: "#111111"
            implicitHeight: 34
            anchors {
                top: true
                left: true
                right: true
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 14

                Text {
                    text: "BreakLand"
                    color: "#f2f2f2"
                    font.family: "Sans"
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    text: "1  2  3  4  5"
                    color: "#b8b8b8"
                    font.family: "Sans"
                    font.pixelSize: 13
                }

                Item { Layout.fillWidth: true }

                Text {
                    id: clock
                    color: "#f2f2f2"
                    font.family: "Sans"
                    font.pixelSize: 13
                    text: Qt.formatDateTime(new Date(), "ddd  HH:mm")

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd  HH:mm")
                    }
                }
            }
        }
    }
}
