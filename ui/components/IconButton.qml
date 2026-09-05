import QtQuick

Rectangle {
    id: btn

    property string iconSource: ""
    property color iconColor: "#99ffffff"
    property color hoverColor: "#ffffff"
    property color hoverBg: "#1affffff"
    property bool active: false
    property color activeColor: "#60a5fa"
    property int iconSize: 14
    property string tooltip: ""

    width: 28
    height: 28
    radius: width / 2
    color: active ? "#1affffff" : "transparent"
    border.width: 0

    signal clicked()

    Image {
        anchors.centerIn: parent
        source: btn.iconSource
        sourceSize.width: btn.iconSize
        sourceSize.height: btn.iconSize
        opacity: active ? 1.0 : (mouseArea.containsMouse ? 1.0 : 0.7)

        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: btn.clicked()
    }

    states: [
        State {
            name: "hover"
            when: mouseArea.containsMouse && !btn.active
            PropertyChanges { target: btn; color: btn.hoverBg }
        }
    ]

    Behavior on color { ColorAnimation { duration: 150 } }
}
