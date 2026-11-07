import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool locked: false
    property bool unlocking: false
    property string password: ""
    property string errorMessage: ""

    FileView {
        id: skullFile
        path: Qt.resolvedUrl("./skull.txt")
        blockLoading: true
    }

    IpcHandler {
        target: "breakland"

        function lock() {
            if (!root.locked) {
                root.password = ""
                root.errorMessage = ""
                root.unlocking = false
                root.locked = true
            }
        }
    }

    PamContext {
        id: pam
        config: "login"

        onPamMessage: {
            if (responseRequired)
                pam.respond(root.password)
        }
        onCompleted: function (result) {
            if (result === PamResult.Success) {
                root.unlocking = true
                unlockAnimation.restart()
            } else {
                root.errorMessage = message || "Authentication failed"
                root.password = ""
            }
        }
    }

    Timer {
        id: unlockAnimation
        interval: 800
        onTriggered: {
            root.unlocking = false
            root.locked = false
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: root.locked

        surface: Component {
            WlSessionLockSurface {
                id: lockSurface
                color: "#000000"

                property bool primaryScreen: screen === Quickshell.screens[0]
                property real skullWidth: Math.min(width * 0.86, 1180)
                property real skullHeight: Math.min(height * 0.72, 620)

                Item {
                    anchors.fill: parent

                    Item {
                        id: skull
                        width: lockSurface.skullWidth
                        height: lockSurface.skullHeight
                        anchors.centerIn: parent

                        Rectangle {
                            id: leftMask
                            width: parent.width / 2
                            height: parent.height
                            x: root.unlocking ? -70 : 0
                            color: "transparent"
                            clip: true

                            Behavior on x {
                                NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                            }

                            Text {
                                text: skullFile.text()
                                color: "#f2f2f2"
                                font.family: "monospace"
                                font.pixelSize: Math.max(5, Math.min(11, lockSurface.width / 150))
                                lineHeight: font.pixelSize
                                lineHeightMode: Text.FixedHeight
                                wrapMode: Text.NoWrap
                                width: skull.width
                                height: skull.height
                                opacity: root.unlocking ? 0.25 : 1
                                Behavior on opacity {
                                    NumberAnimation { duration: 650; easing.type: Easing.OutQuad }
                                }
                            }
                        }

                        Rectangle {
                            id: rightMask
                            width: parent.width / 2
                            height: parent.height
                            x: parent.width / 2 + (root.unlocking ? 70 : 0)
                            color: "transparent"
                            clip: true

                            Behavior on x {
                                NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                            }

                            Text {
                                text: skullFile.text()
                                x: -skull.width / 2
                                color: "#f2f2f2"
                                font.family: "monospace"
                                font.pixelSize: Math.max(5, Math.min(11, lockSurface.width / 150))
                                lineHeight: font.pixelSize
                                lineHeightMode: Text.FixedHeight
                                wrapMode: Text.NoWrap
                                width: skull.width
                                height: skull.height
                                opacity: root.unlocking ? 0.25 : 1
                                Behavior on opacity {
                                    NumberAnimation { duration: 650; easing.type: Easing.OutQuad }
                                }
                            }
                        }

                        Repeater {
                            model: 18

                            Text {
                                required property int index
                                text: ["⣿", "⣷", "⣤", "⠿", "⣀"][index % 5]
                                color: "#f2f2f2"
                                font.family: "monospace"
                                font.pixelSize: 12
                                x: skull.width / 2 + (index % 6 - 3) * 18
                                y: root.unlocking ? skull.height + 30 + index * 5 : skull.height / 2
                                opacity: root.unlocking ? 0 : 1
                                Behavior on y {
                                    NumberAnimation { duration: 600 + index * 12; easing.type: Easing.InQuad }
                                }
                                Behavior on opacity {
                                    NumberAnimation { duration: 500; easing.type: Easing.InQuad }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Math.max(35, parent.height * 0.08)
                        width: Math.min(parent.width * 0.7, 420)
                        spacing: 10
                        visible: lockSurface.primaryScreen
                        opacity: root.unlocking ? 0 : 1

                        Behavior on opacity {
                            NumberAnimation { duration: 250 }
                        }

                        TextInput {
                            id: passwordInput
                            Layout.fillWidth: true
                            color: "#f2f2f2"
                            horizontalAlignment: Text.AlignHCenter
                            echoMode: TextInput.Password
                            font.family: "Sans"
                            font.pixelSize: 18
                            focus: root.locked && lockSurface.primaryScreen
                            onTextChanged: root.password = text
                            onAccepted: {
                                if (!pam.active && text.length > 0)
                                    pam.start()
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.errorMessage
                            color: "#ff7777"
                            horizontalAlignment: Text.AlignHCenter
                            visible: text.length > 0
                        }
                    }
                }

                Component.onCompleted: {
                    if (primaryScreen)
                        passwordInput.forceActiveFocus()
                }
            }
        }
    }

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
