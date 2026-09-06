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
    scale: mouseArea.pressed ? 0.90 : 1.0

    signal clicked()

    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.Linear } }

    Image {
        anchors.centerIn: parent
        source: btn.iconSource
        sourceSize.width: btn.iconSize
        sourceSize.height: btn.iconSize
        opacity: active ? 1.0 : (mouseArea.containsMouse ? 1.0 : 0.75)

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.Linear } }
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

    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.Linear } }
}
