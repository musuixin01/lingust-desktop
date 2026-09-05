import QtQuick

Row {
    id: lights
    spacing: 6

    property bool compact: false

    signal closeClicked()
    signal minimizeClicked()
    signal refreshClicked()

    Repeater {
        model: [
            { color: DesignTokens.lightRed, action: "close" },
            { color: DesignTokens.lightAmber, action: "minimize" },
            { color: DesignTokens.lightEmerald, action: "refresh" }
        ]

        delegate: Rectangle {
            width: lights.compact ? 8 : 12
            height: width
            radius: width / 2
            color: modelData.color
            opacity: 0.8

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (modelData.action === "close") lights.closeClicked()
                    else if (modelData.action === "minimize") lights.minimizeClicked()
                    else lights.refreshClicked()
                }
                onEntered: parent.opacity = 1.0
                onExited: parent.opacity = 0.8
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
}
