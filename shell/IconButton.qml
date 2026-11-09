import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string iconSource
    property string tooltipText
    signal clicked(int button)
    signal wheelChanged(real delta)

    width: 26
    height: 26
    radius: 5
    color: mouse.containsMouse ? "#292929" : "transparent"

    Image {
        anchors.centerIn: parent
        width: 14
        height: 14
        source: root.iconSource
        sourceSize: Qt.size(32, 32)
        smooth: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: root.clicked(mouse.button)
        onWheel: root.wheelChanged(wheel.angleDelta.y)
    }

    ToolTip.visible: mouse.containsMouse
    ToolTip.text: root.tooltipText
    ToolTip.delay: 450
}
