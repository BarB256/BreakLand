import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

ShellRoot {
    id: root
    property var theme: BreakLandTheme { }

    property bool locked: false
    property bool unlocking: false
    property string password: ""
    property string errorMessage: ""
    property var workspaces: []
    property int activeWorkspace: 1
    property string volumeStatus: "--"
    property string brightnessStatus: "--"
    property string batteryStatus: "--"
    property string networkStatus: "--"

    function refreshWorkspaces() {
        if (!workspaceQuery.running)
            workspaceQuery.running = true
        if (!activeWorkspaceQuery.running)
            activeWorkspaceQuery.running = true
    }

    function updateWorkspaces(raw) {
        try {
            const parsed = JSON.parse(raw)
            if (Array.isArray(parsed))
                workspaces = parsed.sort((a, b) => a.id - b.id)
        } catch (error) {
            console.warn("BreakLand workspace query failed:", error)
        }
    }

    function updateActiveWorkspace(raw) {
        try {
            const parsed = JSON.parse(raw)
            if (parsed && parsed.id !== undefined)
                activeWorkspace = parsed.id
        } catch (error) {
            console.warn("BreakLand active workspace query failed:", error)
        }
    }

    Process {
        id: workspaceQuery
        command: ["breakctl", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: root.updateWorkspaces(text)
        }
    }

    Process {
        id: activeWorkspaceQuery
        command: ["breakctl", "-j", "activeworkspace"]
        stdout: StdioCollector {
            onStreamFinished: root.updateActiveWorkspace(text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.refreshWorkspaces()
            if (!volumeQuery.running) volumeQuery.running = true
            if (!brightnessQuery.running) brightnessQuery.running = true
            if (!batteryQuery.running) batteryQuery.running = true
            if (!networkQuery.running) networkQuery.running = true
        }
    }

    Process {
        id: terminalProcess
        command: ["ghostty"]
    }

    Process {
        id: launcherProcess
        command: ["fuzzel"]
    }

    Process {
        id: lockProcess
        command: ["breakland-shell", "--lock"]
    }

    Process {
        id: volumeMuteProcess
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    Process {
        id: volumeStepProcess
        command: ["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "5%+"]
    }

    Process {
        id: brightnessStepProcess
        command: ["brightnessctl", "-e4", "-n2", "set", "5%+"]
    }

    Process {
        id: volumeQuery
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Volume:\s+([0-9.]+)/)
                root.volumeStatus = match ? Math.round(Number(match[1]) * 100) + "%" : "--"
                if (text.includes("MUTED")) root.volumeStatus = "muted"
            }
        }
    }

    Process {
        id: brightnessQuery
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/;([0-9]+)%;/)
                root.brightnessStatus = match ? match[1] + "%" : "--"
            }
        }
    }

    Process {
        id: batteryQuery
        command: ["sh", "-c", "for b in /sys/class/power_supply/BAT*/capacity; do cat \"$b\"; exit; done; echo --"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                root.batteryStatus = value === "--" ? "--" : value + "%"
            }
        }
    }

    Process {
        id: networkQuery
        command: ["sh", "-c", "nmcli -t -f STATE general 2>/dev/null || echo unknown"]
        stdout: StdioCollector {
            onStreamFinished: root.networkStatus = text.trim() || "unknown"
        }
    }

    Process {
        id: workspaceNextProcess
        command: ["breakctl", "dispatch", "hl.dsp.focus({ workspace = 'e+1' })"]
    }

    Process {
        id: workspacePreviousProcess
        command: ["breakctl", "dispatch", "hl.dsp.focus({ workspace = 'e-1' })"]
    }

    Process {
        id: sessionAction
        command: ["true"]
    }

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

    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"
            implicitHeight: 42
            anchors {
                top: true
                left: true
                right: true
                topMargin: 6
                leftMargin: 10
                rightMargin: 10
            }

            Rectangle {
                anchors.fill: parent
                color: root.theme.surface
                border.color: root.theme.border
                border.width: 1
                radius: root.theme.radius
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Repeater {
                    model: root.workspaces.length > 0 ? root.workspaces : [
                        { id: 1, name: "1" },
                        { id: 2, name: "2" },
                        { id: 3, name: "3" },
                        { id: 4, name: "4" },
                        { id: 5, name: "5" },
                    ]

                    Rectangle {
                        required property var modelData
                        width: 20
                        height: 20
                        radius: 3
                        color: modelData.id === root.activeWorkspace ? "#f2f2f2" : "#262626"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name || modelData.id
                            color: modelData.id === root.activeWorkspace ? "#090909" : "#b8b8b8"
                            font.family: "monospace"
                            font.pixelSize: 11
                        }

                        ToolTip.visible: mouse.containsMouse
                        ToolTip.text: "Workspace " + modelData.id

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: workspaceProcess.running = true
                            onWheel: {
                                if (wheel.angleDelta.y > 0)
                                    workspacePreviousProcess.running = true
                                else
                                    workspaceNextProcess.running = true
                            }

                            Process {
                                id: workspaceProcess
                                command: [
                                    "breakctl",
                                    "dispatch",
                                    "hl.dsp.focus({ workspace = '" + modelData.name + "' })",
                                ]
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    iconSource: Qt.resolvedUrl("./icons/volume.svg")
                    tooltipText: "Audio: " + root.volumeStatus + " · click mute · wheel adjusts"
                    onClicked: volumeMuteProcess.running = true
                    onWheelChanged: {
                        volumeStepProcess.command = [
                            "wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@",
                            delta > 0 ? "5%+" : "5%-",
                        ]
                        volumeStepProcess.running = true
                    }
                }

                IconButton {
                    iconSource: Qt.resolvedUrl("./icons/network.svg")
                    tooltipText: "Network: " + root.networkStatus
                }

                IconButton {
                    iconSource: Qt.resolvedUrl("./icons/battery.svg")
                    tooltipText: "Battery: " + root.batteryStatus + " · wheel adjusts brightness"
                    onWheelChanged: {
                        brightnessStepProcess.command = [
                            "brightnessctl", "-e4", "-n2", "set", delta > 0 ? "5%+" : "5%-",
                        ]
                        brightnessStepProcess.running = true
                    }
                }

                IconButton {
                    iconSource: Qt.resolvedUrl("./icons/lock.svg")
                    tooltipText: "Lock screen · Super+L"
                    onClicked: lockProcess.running = true
                }

                IconButton {
                    iconSource: Qt.resolvedUrl("./icons/power.svg")
                    tooltipText: "Session actions"
                    onClicked: sessionMenu.open()
                }

                Popup {
                    id: sessionMenu
                    x: parent.width - width - 8
                    y: parent.height + 4
                    width: 180
                    padding: 8
                    background: Rectangle {
                        color: "#101010"
                        border.color: "#444444"
                        border.width: 1
                        radius: 4
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4

                        Button {
                            text: "Lock"
                            Layout.fillWidth: true
                            onClicked: {
                                sessionMenu.close()
                                lockProcess.running = true
                            }
                        }

                        Button {
                            text: "Exit BreakLand"
                            Layout.fillWidth: true
                            onClicked: {
                                sessionMenu.close()
                                sessionAction.command = ["breakctl", "dispatch", "hl.dsp.exit()"]
                                sessionAction.running = true
                            }
                        }

                        Button {
                            text: "Reboot"
                            Layout.fillWidth: true
                            onClicked: {
                                sessionMenu.close()
                                sessionAction.command = ["systemctl", "reboot"]
                                sessionAction.running = true
                            }
                        }

                        Button {
                            text: "Power off"
                            Layout.fillWidth: true
                            onClicked: {
                                sessionMenu.close()
                                sessionAction.command = ["systemctl", "poweroff"]
                                sessionAction.running = true
                            }
                        }
                    }
                }
            }

            Text {
                id: clock
                anchors.centerIn: parent
                color: "#f2f2f2"
                font.family: "monospace"
                font.pixelSize: 11
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
