import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string iconSource
    property string tooltipText
    signal clicked

    width: 32
    height: 32
    radius: 5
    color: mouse.containsMouse ? "#292929" : "transparent"

    Image {
        anchors.centerIn: parent
        width: 17
        height: 17
        source: root.iconSource
        sourceSize: Qt.size(32, 32)
        smooth: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    ToolTip.visible: mouse.containsMouse
    ToolTip.text: root.tooltipText
    ToolTip.delay: 450
}
